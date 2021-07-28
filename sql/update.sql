.import --csv ${my_datasrc_dir}/${csv_file} ${csv_temp}

CREATE TABLE IF NOT EXISTS ${ccy_temp} AS
       SELECT '${nrm_date}' AS DT, 'EUR' AS CCY, '1.00' AS VAL UNION ALL
       SELECT '${nrm_date}' AS DT, 'USD' AS CCY, ${csv_temp}.' USD' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'JPY' AS CCY, ${csv_temp}.' JPY' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'BGN' AS CCY, ${csv_temp}.' BGN' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'CZK' AS CCY, ${csv_temp}.' CZK' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'DKK' AS CCY, ${csv_temp}.' DKK' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'GBP' AS CCY, ${csv_temp}.' GBP' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'HUF' AS CCY, ${csv_temp}.' HUF' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'PLN' AS CCY, ${csv_temp}.' PLN' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'RON' AS CCY, ${csv_temp}.' RON' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'SEK' AS CCY, ${csv_temp}.' SEK' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'CHF' AS CCY, ${csv_temp}.' CHF' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'ISK' AS CCY, ${csv_temp}.' ISK' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'NOK' AS CCY, ${csv_temp}.' NOK' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'HRK' AS CCY, ${csv_temp}.' HRK' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'RUB' AS CCY, ${csv_temp}.' RUB' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'TRY' AS CCY, ${csv_temp}.' TRY' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'AUD' AS CCY, ${csv_temp}.' AUD' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'BRL' AS CCY, ${csv_temp}.' BRL' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'CAD' AS CCY, ${csv_temp}.' CAD' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'CNY' AS CCY, ${csv_temp}.' CNY' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'HKD' AS CCY, ${csv_temp}.' HKD' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'IDR' AS CCY, ${csv_temp}.' IDR' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'ILS' AS CCY, ${csv_temp}.' ILS' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'INR' AS CCY, ${csv_temp}.' INR' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'KRW' AS CCY, ${csv_temp}.' KRW' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'MXN' AS CCY, ${csv_temp}.' MXN' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'MYR' AS CCY, ${csv_temp}.' MYR' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'NZD' AS CCY, ${csv_temp}.' NZD' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'PHP' AS CCY, ${csv_temp}.' PHP' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'SGD' AS CCY, ${csv_temp}.' SGD' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'THB' AS CCY, ${csv_temp}.' THB' AS VAL FROM ${csv_temp} UNION ALL
       SELECT '${nrm_date}' AS DT, 'ZAR' AS CCY, ${csv_temp}.' ZAR' AS VAL FROM ${csv_temp};

DELETE FROM CCY_XRATES WHERE DT = '${nrm_date}';

INSERT INTO CCY_XRATES SELECT DT,CCY,VAL FROM ${ccy_temp} ORDER BY CCY ASC;
