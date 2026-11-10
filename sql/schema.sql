CREATE TABLE IF NOT EXISTS `bl_idcard_photo_store` (
  `id`          INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `hash`        BINARY(32)       NOT NULL,
  `mime`        VARCHAR(16)      NOT NULL,
  `bytes`       SMALLINT UNSIGNED NOT NULL,
  `data`        BLOB             NOT NULL,
  `created_at`  DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `used_at`     DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_hash` (`hash`),
  INDEX `idx_used` (`used_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `bl_idcard_cards` (
  `card_id`     VARCHAR(16)      NOT NULL,
  `citizenid`   VARCHAR(64)      NOT NULL,
  `photo_id`    INT UNSIGNED     NULL,
  `created_at`  DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`card_id`),
  INDEX `idx_cid` (`citizenid`),
  INDEX `idx_photo` (`photo_id`),
  CONSTRAINT `fk_bl_idcard_cards_photo` FOREIGN KEY (`photo_id`) REFERENCES `bl_idcard_photo_store` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `bl_idcard_profiles` (
  `citizenid`   VARCHAR(64)      NOT NULL,
  `photo_id`    INT UNSIGNED     NOT NULL,
  `updated_at`  DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`citizenid`),
  INDEX `idx_photo` (`photo_id`),
  CONSTRAINT `fk_bl_idcard_profiles_photo` FOREIGN KEY (`photo_id`) REFERENCES `bl_idcard_photo_store` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
