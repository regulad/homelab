<?php

declare(strict_types=1);

// SPDX-License-Identifier: AGPL-3.0-or-later

namespace OCA\NewsMail\Service;

use OCA\News\Db\Feed;
use OCA\News\Db\Item;
use OCA\News\Service\Exceptions\ServiceNotFoundException;
use OCA\News\Service\FeedServiceV2;
use OCA\News\Service\ItemServiceV2;
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
 * Mails each News user their unread entries, one mail per feed, to their own
 * address from Nextcloud's, and marks each mail's entries read in News once it
 * has gone out. Whether an entry is unread is all that decides: News fetches
 * new entries unread, so each feed update's go out once. News's services are
 * looked up only once News is known to be enabled.
 */
class NewEntries {
	public function __construct(
		private IUserManager $userManager,
		private IMailer $mailer,
		private IURLGenerator $urlGenerator,
		private IL10N $l,
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
				// What was not mailed is still unread, so the next run tries
				// it again.
				$this->logger->error('Mailing {user} the unread entries of their News feeds failed', [
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
		$user = $this->userManager->get($userId);
		$address = $user?->getEMailAddress();
		if ($user === null || !$user->isEnabled() || $address === null || $address === '') {
			return;
		}

		/** @var array<int, Item[]> $entriesByFeed */
		$entriesByFeed = [];
		foreach ($items->findAllForUser($userId, ['items.unread' => true]) as $item) {
			// A feed's keyword filter hides the entries it matches.
			if (!$item->isFiltered() && isset($feeds[$item->getFeedId()])) {
				$entriesByFeed[$item->getFeedId()][] = $item;
			}
		}

		foreach ($entriesByFeed as $feedId => $entries) {
			// Newest first, as News lists them.
			usort($entries, fn (Item $a, Item $b): int => $b->getId() <=> $a->getId());
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

	/**
	 * @param Item[] $entries
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
