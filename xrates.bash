#!/usr/bin/env -S bash --norc --noprofile
#shellcheck source=/dev/null disable=SC2155,SC2034,SC2154
#

# Unofficial Bash Strict Mode
set -eo pipefail
IFS=$'\t\n'

#link free (S)cript: (D)ir(N)ame, (B)ase(N)ame.
declare -r sdn="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
declare -r sbn="$(basename "$(realpath "${BASH_SOURCE[0]}")")"
declare -r database_dir="${sdn}/databases"
declare -r database_fn="${database_dir}/database.db"
declare -r myusage="
Name: ${sbn}
Usage: ${sbn} update | send_sql 'sql statement' | showme [...] 
Description: Manipulate/Query sqlite ${database_fn}
Examples: ${sbn} update # Populate sqlite with available rates
	  ${sbn} send_sql 'sql statement' # Sends 'sql statement' to parse through sqlite.
	  ${sbn} showme defunct # Show old currencies and their last valuation
	  ${sbn} showme last # Shows latest eur xrates
	  ${sbn} showme last date # Shows the last date imported
	  ${sbn} showme dates # Shows all the dates with rates stored
	  ${sbn} showme eur # Will show all eur xrates for the latest available date
	  ${sbn} showme eur gbp # Will show last eur to gbp xrate
	  ${sbn} showme 20201023 # Will show ALL xrates for given date (if any)
	  ${sbn} showme 20201023 eur # Will show all xrates for eur in given date
	  ${sbn} showme 20201023 eur gbp # Will show eur xrate to gbp for given date
"

_date(){
    #Caution: Date magic ahead - DONT MESS WITH VOODOO!
    source /etc/os-release
    if [[ "${NAME}" =~ BSD$ ]]; then
	for arg in "${@}"; do
	    case "${arg}" in
		-d)
		    if [[ "${2}" =~ - ]]; then
			local myargs+=("-j" "-f" "%Y-%m-%d")
		    elif [[ "${2}" =~ / ]]; then
			local myargs+=("-j" "-f" "%Y/%m/%d")
		    elif [[ "${2}" =~ [[:alpha:]] ]]; then
			local myargs+=("-j" "-f" "%d %B %Y")
			# set -- "${1}" "${2:0:2} ${2:3:3} ${2:(-4)}" "${@:2}"
		    elif [[ "${2}" == "${2//[![:digit:]]}" ]]; then
			case "${#2}" in
			    6) local myargs+=("-j" "-f" "%y%m%d");;
			    8) local myargs+=("-j" "-f" "%Y%m%d");;
			    10) local myargs+=("-j" "-f" "%s");;
			    *) return 1;;
			esac
		    else
			return 1
		    fi;;
		-u) local myargs+=("${arg}" "-j");;
		*) local myargs+=("${arg}");;
	    esac
	done
    else
	local myargs=( "${@}" )
    fi
    # Clean up temp sources (source /etc/os-release)
    unset NAME VERSION VERSION_ID ID ANSI_COLOR PRETTY_NAME CPE_NAME HOME_URL BUG_REPORT_URL
    date "${myargs[@]}"
}

log2err(){ echo -ne "${sbn}: ${*}\n" >&2; }

send_sql() {
    case "${#}" in
	1) echo -ne "${1}" | "sqlite3" "${database_fn}";;
	*) log2err "${FUNCNAME[0]}: Usage: ${sbn} ${FUNCNAME[0]} 'query string to parse'"; return 1;;
    esac
}

showme() {
    local dt=''
    local -r thisusage="${FUNCNAME[0]}: Usage: ${sbn} ${FUNCNAME[0]} defunct|last [date]|dates|from_ccy|from_ccy to_ccy|[date |[from_ccy|[to_ccy]]]"
    local -r preview_mode=".mode box\n.headers on\n"

    defunct() {
	echo -ne "${preview_mode}SELECT * FROM DEF_CCY_XRATES ORDER BY CCY ASC;\n" | "sqlite3" "${database_fn}"
    }

    dates() {
	echo -ne "${preview_mode}SELECT DT FROM CCY_XRATES GROUP BY DT ORDER BY DT ASC;\n" | "sqlite3" "${database_fn}"
    }

    last() {
	if [[ -z "${1}" ]]; then
	    echo -ne "${preview_mode}SELECT * FROM LAST_XRATES WHERE FROM_CCY LIKE 'EUR' ORDER BY TO_CCY ASC;\n" | "sqlite3" "${database_fn}"
	elif [[ -n "${1}" && "${1}" == "date" ]]; then
	    echo -ne ".mode list\n.headers off\nSELECT MAX(DT) AS MAX_DATE FROM CCY_XRATES;\n" | "sqlite3" "${database_fn}"
	else
	    log2err "${thisusage}"
	    return 1
	fi
    }

    case "${1}" in
	-h|--help) log2err "${thisusage}"; return 1;;
	last|dates|defunct) "${@}";;
	*)
	    if [[ "${#}" -eq "1" || "${#}" -eq "2" || "${#}" -eq "3" ]]; then
		if _date -d "${1}" +%F &> /dev/null; then
		    local dt="$(_date -d "${1}" +%F)"
		fi
		case "${#}" in
		    1)
			if _date -d "${1}" +%F &> /dev/null; then
			    echo -ne "${preview_mode}SELECT * FROM XRATES WHERE DT = '${dt}';\n" | "sqlite3" "${database_fn}"
			elif [[ "${1//[![:alpha:]]}" == "${1}" && "${#1}" -eq "3" ]]; then
			    echo -ne "${preview_mode}SELECT * FROM LAST_XRATES WHERE FROM_CCY = '${1^^}';\n" | "sqlite3" "${database_fn}"
			else
			    log2err "${FUNCNAME[0]}: Input either a date or a currency. eg: yyyymmdd or eur!\n${thisusage}"
			    return 1
			fi;;
		    2)
			if _date -d "${1}" +%F &> /dev/null; then
			    echo -ne "${preview_mode}SELECT * FROM XRATES WHERE DT = '${dt}' AND FROM_CCY = '${2^^}';\n" | "sqlite3" "${database_fn}"
			else
			    echo -ne "${preview_mode}SELECT * FROM LAST_XRATES WHERE FROM_CCY = '${1^^}' AND TO_CCY = '${2^^}';\n" | "sqlite3" "${database_fn}"
			fi;;
		    3) echo -ne "${preview_mode}SELECT * FROM XRATES WHERE DT = '${dt}' AND FROM_CCY = '${2^^}' AND TO_CCY = '${3^^}';\n" | "sqlite3" "${database_fn}";;
		esac
	    else
		log2err "${thisusage}"
		return 1
	    fi
    esac
}

update() {
    local -r zip_src="https://www.ecb.europa.eu/stats/eurofxref/eurofxref.zip"
    local -r zip_file="${zip_src##*/}"
    local -r csv_file="${zip_file//.zip/.csv}"
    local -r data_sources_dir="${sdn}/sources"
    local -r initial_sql="${sdn}/sql/initial.sql"
    local -r tmp_dir="/tmp/${USER}/${$}"
    local -r zip_fpth="${tmp_dir}/${zip_file}"
    local -r csv_fpth="${tmp_dir}/${csv_file}"
    local -r sql_file="${tmp_dir}/${FUNCNAME[0]}.sql"

    prep_things() {
	if [[ "${1}" == "cleanup" ]];then
	    mkdir -p "${2}"
	    mv -f "${tmp_dir}"/* "${2}/"
	    rm -rf "${tmp_dir}/"
	else
	    mkdir -p "${tmp_dir}"
	    curl -sSL "${zip_src}" > "${zip_fpth}"
	    unzip -qod "${tmp_dir}" "${zip_fpth}"
	fi
    }

    prep_things || { log2err "Deal with errors above and try again!"; return 1; }

    local -r csv_flds="$(head -1 "${csv_fpth}")"
    local -r csv_data="$(tail -1 "${csv_fpth}")"
    local -ar csv_farr=( ${csv_flds//,/$'\n'} )
    local -ar csv_darr=( ${csv_data//,/$'\n'} )

    local -r csv_date="${csv_darr[0]}"
    local -r nrm_date="$(_date -d "${csv_date}" +%F)"
    local -r nrm_stmp="$(_date -d "${csv_date}" +%s)"
    local -r my_datasrc_dir="${data_sources_dir}/${FUNCNAME[0]}/$(_date -d "${nrm_stmp}" +%Y)/$(_date -d "${nrm_stmp}" +%m)/$(_date -d "${nrm_stmp}" +%d)"

    _date -d "${nrm_date}" +%s &> /dev/null || { log2err "No valid date found!"; return 1; }

    local mysql="$(cat "${initial_sql}")"
    local mysql+="\n.bail on\nBEGIN TRANSACTION;\n"
    local mysql+="DELETE FROM CCY_XRATES WHERE DT = '${nrm_date}';\n"
    local mysql+="INSERT INTO CCY_XRATES VALUES('${nrm_date}', 'EUR', '1.0000');\n"
    for (( i = 1; i < ${#csv_farr[*]} - 1 ; i++ )); do
	local mysql+="INSERT INTO CCY_XRATES VALUES('${nrm_date}', '${csv_farr[i]//[[:space:]]}', '${csv_darr[i]//[[:space:]]}');\n"
    done
    local mysql+="COMMIT;\nVACUUM;\n"

    echo -ne "${mysql}" > "${sql_file}"

    "sqlite3" "${database_fn}" < "${sql_file}"

    prep_things "cleanup" "${my_datasrc_dir}"

    log2err "${FUNCNAME[0]}: Imported xrates for: ${nrm_date}!"
}

main() {
    if [[ "${#}" == "0" || "${1}" =~ -h ]]; then
	log2err "${FUNCNAME[0]}: ${myusage}"
	return 1
    else
	"${@}"
    fi
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "${@}"
