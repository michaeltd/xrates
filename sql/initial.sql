PRAGMA foreign_keys=OFF;

BEGIN TRANSACTION;

CREATE TABLE IF NOT EXISTS DEF_CCY_XRATES(
  LAST_DATE DATE,
  CCY NCHAR(3),
  VAL DECIMAL(6,6),
  DESC NCHAR(50)
);

INSERT OR REPLACE INTO DEF_CCY_XRATES VALUES('2002-02-28','ATS','13.7603','Austria, Schilling');
INSERT OR REPLACE INTO DEF_CCY_XRATES VALUES('2002-02-28','BEF','40.3399','Belgium, Franc');
INSERT OR REPLACE INTO DEF_CCY_XRATES VALUES('2008-01-31','CYP','0.58527','Cyprus, Pound');
INSERT OR REPLACE INTO DEF_CCY_XRATES VALUES('2002-02-28','DEM','1.95583','Germany, Deutsche Mark');
INSERT OR REPLACE INTO DEF_CCY_XRATES VALUES('2011-01-15','EEK','15.6466','Estonia, Kroon');
INSERT OR REPLACE INTO DEF_CCY_XRATES VALUES('2002-02-28','ESP','166.386','Spain, Peseta');
INSERT OR REPLACE INTO DEF_CCY_XRATES VALUES('2008-01-31','FIM','5.94573','Finland, Markka');
INSERT OR REPLACE INTO DEF_CCY_XRATES VALUES('2002-02-17','FRF','6.55957','France, Franc');
INSERT OR REPLACE INTO DEF_CCY_XRATES VALUES('2002-02-28','GRD','340.750','Greece, Drachma');
INSERT OR REPLACE INTO DEF_CCY_XRATES VALUES('2002-02-09','IEP','0.78756','Ireland, Pound');
INSERT OR REPLACE INTO DEF_CCY_XRATES VALUES('2002-02-28','ITL','1936.27','Italy, Lira');
INSERT OR REPLACE INTO DEF_CCY_XRATES VALUES('2015-01-15','LTL','3.45280','Lithuania, Litas');
INSERT OR REPLACE INTO DEF_CCY_XRATES VALUES('2002-02-28','LUF','40.3399','Luxembourg, Franc');
INSERT OR REPLACE INTO DEF_CCY_XRATES VALUES('2014-01-15','LVL','0.70280','Latvia, Lats');
INSERT OR REPLACE INTO DEF_CCY_XRATES VALUES('2008-01-31','MTL','0.42930','Malta, Lira');
INSERT OR REPLACE INTO DEF_CCY_XRATES VALUES('2008-01-28','NLG','2.20371','Netherlands, Guilder (Florin)');
INSERT OR REPLACE INTO DEF_CCY_XRATES VALUES('2002-02-28','PTE','200.482','Portugal, Escudo');
INSERT OR REPLACE INTO DEF_CCY_XRATES VALUES('2007-01-14','SIT','239.640','Slovenia, Tolar');
INSERT OR REPLACE INTO DEF_CCY_XRATES VALUES('2009-01-17','SKK','30.1260','Slovakia, Koruna');

CREATE TABLE IF NOT EXISTS CCY_XRATES(
  DT DATE NOT NULL,
  CCY NCHAR(3) NOT NULL,
  VAL DECIMAL(6,6) NOT NULL,
  PRIMARY KEY(DT,CCY)
);

CREATE VIEW IF NOT EXISTS XRATES AS
SELECT
  CCY_XRATES.DT AS DT,
  CCY_XRATES_DOUB.CCY AS FROM_CCY,
  ROUND(CCY_XRATES.VAL/CCY_XRATES_DOUB.VAL,4) AS XRATE,
  CCY_XRATES.CCY AS TO_CCY
FROM
  CCY_XRATES,
  CCY_XRATES AS CCY_XRATES_DOUB
WHERE
  CCY_XRATES.DT = CCY_XRATES_DOUB.DT
ORDER BY
  CCY_XRATES.DT,
  CCY_XRATES.CCY ASC
/* XRATES(DT,FROM_CCY,XRATE,TO_CCY) */;

CREATE VIEW IF NOT EXISTS LAST_DATE AS
SELECT
  MAX(DT) AS MAX_DATE
FROM CCY_XRATES;

CREATE VIEW IF NOT EXISTS LAST_XRATES AS
SELECT
  CCY_XRATES.DT AS DT,
  CCY_XRATES_DOUB.CCY AS FROM_CCY,
  ROUND(CCY_XRATES.VAL/CCY_XRATES_DOUB.VAL,4) AS XRATE,
  CCY_XRATES.CCY AS TO_CCY
FROM
  CCY_XRATES,
  CCY_XRATES AS CCY_XRATES_DOUB
WHERE
  CCY_XRATES.DT = CCY_XRATES_DOUB.DT AND
  CCY_XRATES.DT = (SELECT MAX_DATE FROM LAST_DATE)
ORDER BY
  CCY_XRATES_DOUB.CCY
/* LAST_XRATES(DT,FROM_CCY,XRATE,TO_CCY) */;

COMMIT;
