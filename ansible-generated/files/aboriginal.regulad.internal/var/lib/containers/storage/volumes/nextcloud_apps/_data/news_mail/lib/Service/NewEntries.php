<?php

declare(strict_types=1);

// SPDX-License-Identifier: AGPL-3.0-or-later

namespace OCA\NewsMail\Service;

use OCA\News\Db\Feed;
use OCA\News\Db\Item;
use OCA\News\Db\ListType;
use OCA\News\Service\Exceptions\ServiceNotFoundException;
use OCA\News\Service\FeedServiceV2;
use OCA\News\Service\ItemServiceV2;
use OCP\AppFramework\Utility\ITimeFactory;
use OCP\Config\IUserConfig;
use OCP\IL10N;
use OCP\IURLGenerator;
use OCP\IUser;
use OCP\IUserManager;
use OCP\Mail\IMailer;
use OCP\Server;
use Psr\Log\LoggerInterface;
use RuntimeException;
use Throwable;

/**
 * Finds the unread entries each News user's feeds gained since the last run,
 * mails them to the user's own address, one mail per feed, from Nextcloud's,
 * and marks each mail's entries read in News once it has gone out.
 *
 * Each user's progress is two values of their own: the highest item ID it has
 * covered, and when it last looked. News's item IDs only grow, so an entry is
 * new when its ID is above the first; News stamps each item it inserts with
 * the time, so only the items stamped since a little before the second are
 * read. News's services are looked up only once News is known to be enabled.
 */
class NewEntries {
	private const APP = 'news_mail';
	// Seconds before the last look that the next starts from, to cover an
	// entry stamped before an ID above it was read.
	private const LOOKBACK = 3600;

	public function __construct(
		private IUserConfig $userConfig,
		private IUserManager $userManager,
		private IMailer $mailer,
		private IURLGenerator $urlGenerator,
		private IL10N $l,
		private ITimeFactory $time,
		private LoggerInterface $logger,
	) {
	}

	public function mailAll(): void {
		$feeds = Server::get(FeedServiceV2::class);
		$items = Server::get(ItemServiceV2::class);

		/** @var array<string, array<int, Feed>> $feedsByUser */
		$feedsByUser = [];
		foreach ($feeds->findAll() as $feed) {
			$feedsByUser[$feed->getUserId()][$feed->getId()] = $feed;
		}

		foreach ($feedsByUser as $userId => $userFeeds) {
			// PHP makes a numeric user ID an integer key.
			$userId = (string)$userId;
			try {
				$this->mailUser($userId, $userFeeds, $items);
			} catch (Throwable $e) {
				// The user's progress stays where it was, so the next run
				// tries again the entries not mailed yet, which are still
				// unread.
				$this->logger->error('Mailing {user} the new entries of their News feeds failed', [
					'user' => $userId,
					'exception' => $e,
				]);
			}
		}
	}

	/**
	 * @param array<int, Feed> $feeds The user's feeds, by ID
	 */
	private function mailUser(string $userId, array $feeds, ItemServiceV2 $items): void {
		$now = $this->time->getTime();
		try {
			$newest = $items->newest($userId)->getId();
		} catch (ServiceNotFoundException) {
			return;
		}

		$covered = $this->userConfig->getValueInt($userId, self::APP, 'covered_item_id', -1);
		$looked = $this->userConfig->getValueInt($userId, self::APP, 'looked_at', $now);
		if ($covered < 0) {
			// A user's first run starts from their newest entry, rather than
			// mailing every entry they already have.
			$this->saveProgress($userId, $newest, $now);
			return;
		}
		if ($newest <= $covered) {
			$this->saveProgress($userId, $covered, $now);
			return;
		}

		/** @var array<int, Item[]> $entriesByFeed */
		$entriesByFeed = [];
		// News stamps its items in microseconds.
		$since = max(0, $looked - self::LOOKBACK) * 1000000;
		foreach ($items->findAllAfter($userId, ListType::UNREAD, $since) as $item) {
			// Items above $newest arrived while this ran; the next run has them.
			if ($item->getId() > $covered && $item->getId() <= $newest
				&& !$item->isFiltered() && isset($feeds[$item->getFeedId()])) {
				$entriesByFeed[$item->getFeedId()][] = $item;
			}
		}

		$user = $this->userManager->get($userId);
		$address = $user?->getEMailAddress();
		if ($user !== null && $user->isEnabled() && $address !== null && $address !== '') {
			foreach ($entriesByFeed as $feedId => $entries) {
				$this->send($user, $address, $feeds[$feedId], $entries);
				foreach ($entries as $entry) {
					try {
						$items->read($userId, $entry->getId(), true);
					} catch (ServiceNotFoundException) {
						// Removed since, with its feed or by News's purge.
					}
				}
			}
		}
		$this->saveProgress($userId, $newest, $now);
	}

	private function saveProgress(string $userId, int $covered, int $looked): void {
		$this->userConfig->setValueInt($userId, self::APP, 'covered_item_id', $covered);
		$this->userConfig->setValueInt($userId, self::APP, 'looked_at', $looked);
	}

	/**
	 * @param Item[] $entries Newest first, as News lists them
	 */
	private function send(IUser $user, string $address, Feed $feed, array $entries): void {
		$feedTitle = $feed->getTitle() ?: $feed->getUrl();
		$count = count($entries);

		$template = $this->mailer->createEMailTemplate('news_mail.new_entries', [
			'feedId' => $feed->getId(),
			'count' => $count,
		]);
		$template->setSubject($count === 1
			? $feedTitle . ': ' . $this->entryTitle($entries[0])
			: $this->l->n('%s: %n new entry', '%s: %n new entries', $count, [$feedTitle]));
		$template->addHeader();
		$template->addHeading($feedTitle);
		foreach ($entries as $entry) {
			$title = $this->entryTitle($entry);
			$link = $this->urlGenerator->linkToRouteAbsolute('news.page.indexview.itemid', ['itemId' => $entry->getId()]);
			// The title is HTML once a plain-text version is given beside it.
			$template->addBodyListItem(
				'<a href="' . htmlspecialchars($link) . '">' . htmlspecialchars($title) . '</a>',
				$entry->getAuthor() ?? '',
				'',
				$title . "\n" . $link,
			);
		}
		$template->addBodyButton(
			$this->l->t('Open %s in News', [$feedTitle]),
			$this->urlGenerator->linkToRouteAbsolute('news.page.indexview.feedid', ['feedId' => $feed->getId()]),
		);
		$template->addFooter();

		$message = $this->mailer->createMessage();
		$message->setTo([$address => $user->getDisplayName()]);
		$message->useTemplate($template);
		$failed = $this->mailer->send($message);
		if ($failed !== []) {
			throw new RuntimeException('The mail server refused ' . implode(', ', $failed));
		}
	}

	private function entryTitle(Item $entry): string {
		return $entry->getTitle() ?: ($entry->getUrl() ?: $this->l->t('Untitled entry'));
	}
}
