CREATE TABLE IF NOT EXISTS `bl_idcard_photos` (
  `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `card_id`     VARCHAR(16)  NOT NULL,
  `citizenid`   VARCHAR(64)  NOT NULL,
  `photo`       MEDIUMTEXT   NOT NULL,
  `created_at`  DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `card_id` (`card_id`),
  INDEX `idx_cid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
