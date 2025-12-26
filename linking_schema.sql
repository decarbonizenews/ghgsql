CREATE TABLE `linking` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `country` VARCHAR(2) NOT NULL,
  `ets` BIGINT unsigned NOT NULL,
  `iep` VARCHAR(128) NOT NULL,
  `probability` FLOAT NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
