#!/usr/bin/env -S bash --norc --noprofile
#shellcheck source=/dev/null disable=SC2155,SC2034,SC2154
#

#link free (S)cript: (D)ir(N)ame, (B)ase(N)ame.
declare -r sdn="$(dirname "$(realpath "${BASH_SOURCE[0]}")")" \
	sbn="$(basename "$(realpath "${BASH_SOURCE[0]}")")"

source "${sdn}/common.src" || exit 1

declare -r myusage="Usage: ${sbn} update_xrates | drop_temps"

drop_temps(){
    IFS=$' \t\n'
    # Drop temps
    local temps=()

    for i in $(sqlite3 "${database_fn}" ".tables"); do
	[[ "$i" =~ ^_ ]] && local temps+=( "$i" )
    done

    [[ "${#temps[*]}" -eq "0" ]] && log2err "${FUNCNAME[0]}: No temp tables found, Nothing left to do!" && return 1
    
    if tty -s; then
	log2err "${FUNCNAME[0]}: Dropping tables: ${temps[*]}!"
	if [[ "$(read -rp "Continue? [y/N]: " r;echo "${r:-N}")" =~ ^[Yy] ]]; then
	    for i in "${temps[@]}"; do
		local query+="DROP TABLE ${i};"
	    done
	    "sqlite3" "${database_fn}" "${query[*]}VACUUM;"
	    log2err "${FUNCNAME[0]}: Temp tables ${temps[*]} dropped!"
	else
	    log2err "${FUNCNAME[0]}: Temp tables ${temps[*]} remain!"
	fi
    else
	log2err "${FUNCNAME[0]}: \"Would\" drop tables: ${temps[*]}!"
    fi
}

update_xrates(){
    # local -r my_datasrc_dir="${data_sources_dir}/${FUNCNAME[0]}/$(date -d "@${time_stamp}" +%Y)/$(date -d "@${time_stamp}" +%m)/$(date -d "@${time_stamp}" +%d)"
    # local -r sql_file="${my_datasrc_dir}/statements.sql"
    # local -r csv_temp="_${time_stamp}_csv"
    # local -r ccy_temp="_${time_stamp}_ccy"

    # local -r zip_src="https://www.ecb.europa.eu/stats/eurofxref/eurofxref.zip"
    # local -r zip_file="${zip_src##*/}"
    # local -r csv_file="${zip_file//.zip/.csv}"

    # mkdir -p "${my_datasrc_dir}"
    # curl -sSL "${zip_src}" > "${my_datasrc_dir}/${zip_file}"
    # unzip -qod "${my_datasrc_dir}" "${my_datasrc_dir}/${zip_file}"

    # local -r csv_data="$(tail -1 "${my_datasrc_dir}/${csv_file}")"
    # local -r csv_date="${csv_data%%,*}"
    # local -r nrm_date="$(date -d "${csv_date}" +%F)"

    local -r zip_src="https://www.ecb.europa.eu/stats/eurofxref/eurofxref.zip"
    local -r zip_file="${zip_src##*/}"
    local -r csv_file="${zip_file//.zip/.csv}"

    local -r tmp_dir="/tmp/${USER}/${$}"
    mkdir -p "${tmp_dir}"
    curl -sSL "${zip_src}" > "${tmp_dir}/${zip_file}"
    unzip -qod "${tmp_dir}" "${tmp_dir}/${zip_file}"

    local -r csv_data="$(tail -1 "${tmp_dir}/${csv_file}")"
    local -r csv_date="${csv_data%%,*}"
    local -r nrm_date="$(date -d "${csv_date}" +%F)"
    local -r nrm_stmp="$(date -d "${csv_date}" +%s)"

    local -r sql_file="${tmp_dir}/statements.sql"
    local -r csv_temp="_${nrm_stmp}_csv"
    local -r ccy_temp="_${nrm_stmp}_ccy"
    
    echo -ne ".import --csv ${tmp_dir}/${csv_file} ${csv_temp}
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
INSERT INTO CCY_XRATES SELECT DT,CCY,VAL FROM ${ccy_temp} ORDER BY CCY ASC;\n" > "${sql_file}"

    "sqlite3" "${database_fn}" < "${sql_file}"

    local -r my_datasrc_dir="${data_sources_dir}/${FUNCNAME[0]}/$(date -d "@${nrm_date}" +%Y)/$(date -d "@${nrm_date}" +%m)/$(date -d "@${nrm_date}" +%d)"
    
    mkdir -p "${my_datasrc_dir}"
    mv -f "${tmp_dir}"/* "${my_datasrc_dir}/"
    rm -rf "${tmp_dir}/"
    
    log2err "${FUNCNAME[0]}: Imported xrates for: ${nrm_date}!"

    drop_temps
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "${@}"
