#!/usr/bin/env -S bash --norc --noprofile
#shellcheck source=/dev/null disable=SC2155,SC2034,SC2154
#

#link free (S)cript: (D)ir(N)ame, (B)ase(N)ame.
declare -r sdn="$(dirname "$(realpath "${BASH_SOURCE[0]}")")" \
	sbn="$(basename "$(realpath "${BASH_SOURCE[0]}")")"

# Unofficial Bash Strict Mode
set -euo pipefail
IFS=$'\t\n'

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

declare -r database_dir="${sdn}/databases"
declare -r data_sources_dir="${sdn}/sources"
declare -r database_fn="${database_dir}/database.db"
declare -r time_stamp="$(_date -u +%s)"
declare -r preview_mode=".mode box\n.headers on\n"
declare -r myusage="
Name: ${sbn}
Usage: ${sbn} update | drop_temps | send_sql 'sql statement' | showme [...] 
Description: Manipulate/Query sqlite ${database_fn}
Examples: ${sbn} update # Populate sqlite with todays xrates
	  ${sbn} drop_temps # Maintainance - Drop temp tables/Cleanup dead space
	  ${sbn} send_sql 'sql statement' # Sends 'sql statement' to parse through sqlite.
	  ${sbn} showme defunct # Show old currencies and their last valuation
	  ${sbn} showme dates # Show dates with eur exchange rates stored
	  ${sbn} showme dates last # Shows the last date imported
	  ${sbn} showme 20201023 # Will show ALL xrates for given date (if any)
	  ${sbn} showme eur # Will show all eur xrates for the last available date
	  ${sbn} showme 20201023 eur # Will show all xrates for eur in given date
	  ${sbn} showme eur gbp # Will show last eur to gbp xrate
	  ${sbn} showme 20201023 eur gbp # Will show eur xrate to gbp for given date
"

log2err(){ echo -ne "${sbn}: ${*}\n" >&2; }

send_sql() {
    case "${#}" in
	1) echo -ne "${1}" | "sqlite3" "${database_fn}";;
	*) log2err "${FUNCNAME[0]}: Usage: ${sbn} ${FUNCNAME[0]} 'query string to parse'"; return 1;;
    esac
}

showme() {
    set +u
    local dt='' thisusage="${FUNCNAME[0]}: Usage: ${sbn} ${FUNCNAME[0]} defunct|dates [last]|from_ccy to_ccy|[date |[from_ccy|[to_ccy]]]"

    defunct() {
	echo -ne "${preview_mode}SELECT * FROM DEF_CCY_XRATES ORDER BY CCY ASC;\n" | "sqlite3" "${database_fn}"
    }

    dates() {
	if [[ -z "${1}" ]]; then
	    echo -ne "${preview_mode}SELECT DT FROM CCY_XRATES GROUP BY DT ORDER BY DT ASC;\n" | "sqlite3" "${database_fn}"
	elif [[ -n "${1}" && "${1}" == "last" ]]; then
	    echo -ne ".mode list\n.headers off\nSELECT MAX(DT) AS MAX_DATE FROM CCY_XRATES;\n" | "sqlite3" "${database_fn}"
	else
	    log2err "${thisusage}"
	    return 1
	fi
    }

    case "${1}" in
	dates|defunct) "${@}";;
	-h|--help)
	    log2err "${thisusage}"
	    return 1;;
	*)
	    if [[ $# -eq 1 || $# -eq 2 || $# -eq 3 ]]; then
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

splitstr(){
    IFS=$'\n' read -d "" -ra arr <<< "${1//${2}/$'\n'}"
    printf "%s\n" "${arr[*]}"
}

trim() {
    local var="${*}"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    printf "%s\n" "${var}"
}

update(){
    local -r zip_src="https://www.ecb.europa.eu/stats/eurofxref/eurofxref.zip"
    local -r zip_file="${zip_src##*/}"
    local -r csv_file="${zip_file//.zip/.csv}"

    local -r tmp_dir="/tmp/${USER}/${$}"

    mkdir -p "${tmp_dir}"
    curl -sSL "${zip_src}" > "${tmp_dir}/${zip_file}"
    unzip -qod "${tmp_dir}" "${tmp_dir}/${zip_file}"
    
    local -r csv_flds="$(head -1 "${tmp_dir}/${csv_file}")"
    local -ar csv_farr=( $(splitstr "${csv_flds}" ',') )
    local -r csv_data="$(tail -1 "${tmp_dir}/${csv_file}")"
    local -ar csv_darr=( $(splitstr "${csv_data}" ',') )

    local -r csv_date="${csv_data%%,*}"
    local -r nrm_date="$(_date -d "${csv_date}" +%F)"
    local -r nrm_stmp="$(_date -d "${csv_date}" +%s)"

    local -r sql_file="${tmp_dir}/${FUNCNAME[0]}.sql"
    
    local mysql=".bail on\n"
    local mysql+="BEGIN TRANSACTION;\n"
    local mysql+="CREATE TABLE IF NOT EXISTS CCY_XRATES(DT TEXT,CCY,VAL TEXT);\n"
    local mysql+="DELETE FROM CCY_XRATES WHERE DT LIKE '${nrm_date}';\n"
    local mysql+="INSERT INTO CCY_XRATES VALUES('${nrm_date}', 'EUR', '1.0000');\n"    
    for (( i = 1; i < ${#csv_farr[*]} - 1 ; i++ )); do
	local mysql+="INSERT INTO CCY_XRATES VALUES('${nrm_date}', '$( trim ${csv_farr[i]} )', '$( trim ${csv_darr[i]} )');\n"
    done
    local mysql+="COMMIT;\nVACUUM;\n"
    
    echo -ne "${mysql}" > "${sql_file}"

    "sqlite3" "${database_fn}" < "${sql_file}"

    local -r my_datasrc_dir="${data_sources_dir}/${FUNCNAME[0]}/$(_date -d "${nrm_stmp}" +%Y)/$(_date -d "${nrm_stmp}" +%m)/$(_date -d "${nrm_stmp}" +%d)"
    
    mkdir -p "${my_datasrc_dir}"
    mv -f "${tmp_dir}"/* "${my_datasrc_dir}/"
    rm -rf "${tmp_dir}/"
    
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
