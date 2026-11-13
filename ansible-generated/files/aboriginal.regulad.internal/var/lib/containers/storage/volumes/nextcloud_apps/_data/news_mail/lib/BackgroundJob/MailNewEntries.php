<?php

declare(strict_types=1);

// SPDX-License-Identifier: AGPL-3.0-or-later

namespace OCA\NewsMail\BackgroundJob;

use OCA\NewsMail\Service\NewEntries;
use OCP\App\IAppManager;
use OCP\AppFramework\Utility\ITimeFactory;
use OCP\BackgroundJob\IJob;
use OCP\BackgroundJob\TimedJob;

/**
 * Mails each News user their unread entries, then marks them read. News
 * fetches its feeds in a background job of its own, so this one runs at every
 * cron run, and a feed's new entries go out at the first run after their
 * fetch.
 */
class MailNewEntries extends TimedJob {
	public function __construct(
		ITimeFactory $time,
		private IAppManager $appManager,
		private NewEntries $newEntries,
	) {
		parent::__construct($time);
		$this->setInterval(60);
		$this->setTimeSensitivity(IJob::TIME_SENSITIVE);
	}

	protected function run($argument): void {
		if ($this->appManager->isEnabledForAnyone('news')) {
			$this->newEntries->mailAll();
		}
	}
}
