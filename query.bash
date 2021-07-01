#!/usr/bin/env -S bash --norc --noprofile
#shellcheck source=/dev/null disable=SC2155,SC2034,SC2154
#

#link free (S)cript: (D)ir(N)ame, (B)ase(N)ame.
declare -r sdn="$(dirname "$(realpath "${BASH_SOURCE[0]}")")" \
	sbn="$(basename "$(realpath "${BASH_SOURCE[0]}")")"

source "${sdn}/common.src" || exit 1

declare -r myusage="
Name: ${sbn}
Usage: ${sbn} xrates ...| bkm ...| agenda ...
Description: Query sqlite ${database_fn}
Examples: ${sbn} xrates defunct # Show old currencies and their last valuation
	  ${sbn} xrates dates # Show dates with eur exchange rates stored
	  ${sbn} xrates dates last # Shows the last date imported
	  ${sbn} xrates 20201023 # Will show ALL xrates for given date (if any)
	  ${sbn} xrates 20201023 eur # Will show all xrates for eur in given date
	  ${sbn} xrates eur gbp # Will show last eur to gbp xrate
	  ${sbn} xrates 20201023 eur gbp # Will show eur xrate to gbp for given date
	  ${sbn} bkm all # Returns all bookmarks
	  ${sbn} bkm add 'https://example.site.org/' # Will add a bookmark for the given site
	  ${sbn} bkm 'google' # Shows bookmarks containing 'google'
	  ${sbn} agenda all # Display all agenda items
	  ${sbn} agenda 'nick' # Display mails and names containing 'nick'
	  ${sbn} send_sql 'sql statement' # Sends 'sql statement' to parse through \${database_fn}.
"

send_sql() {
    case "${#}" in
	1) echo -ne "${1}" | "sqlite3" "${database_fn}";;
	*) log2err "${FUNCNAME[0]}: Usage: ${sbn} ${FUNCNAME[0]} 'query string to parse'"; return 1;;
    esac
}

agenda() {
    case "${#}" in
	1)
	    if [[ "${1}" == "all" ]]; then
		echo -ne "${preview_mode}SELECT * FROM AGENDA;\n" | "sqlite3" "${database_fn}"
	    else
		echo -ne "${preview_mode}SELECT * FROM AGENDA WHERE NAME LIKE '%${1}%' OR MAIL LIKE '%${1}%' OR COMMENTS LIKE '%${1}%';\n" | "sqlite3" "${database_fn}"
	    fi;;
	*) log2err "${FUNCNAME[0]}: Usage: ${sbn} ${FUNCNAME[0]} all | 'query string'"; return 1;;
    esac
}

bkm() {
    local thisusage="${FUNCNAME[0]}: Usage: ${sbn} ${FUNCNAME[0]} all|add 'bookmark'|[query string]"
    case "${#}" in
	1)
	    case "${1}" in
		all) "sqlite3" "${database_fn}" "SELECT * FROM BOOKMARKS;";;
		add) log2err "${thisusage}";return 1;;
		*) "sqlite3" "${database_fn}" "SELECT * FROM BOOKMARKS WHERE LINK LIKE '%${1}%';";;
	    esac;;
	2)
	    case "${1}" in
		add) shift; "sqlite3" "${database_fn}" "INSERT INTO BOOKMARKS (LINK) VALUES('${1}');";;
		*) log2err "${thisusage}"; return 1;;
	    esac;;
	*) log2err "${thisusage}"; return 1;;
    esac
}

xrates() {
    set +u
    local dt='' thisusage="${FUNCNAME[0]}: Usage: ${sbn} ${FUNCNAME[0]} defunct|dates [last]|[date |[from ccy|[to ccy]]]"

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
	*)
	    if [[ $# -eq 1 || $# -eq 2 || $# -eq 3 ]]; then
		if _date -d "${1}" +%F &> /dev/null; then
		    local dt="$(_date -d "${1}" +%F)"
		elif [[ "${1//[![:alpha:]]}" == "${1}" && "${#1}" -eq "3" && "${2//[![:alpha:]]}" == "${2}" && "${#2}" -eq "3" ]]; then
		    local dt="$(_date -d "$(${FUNCNAME[0]} dates last)" +%F)"
		else
		    log2err "${FUNCNAME[0]}: You need a valid date. eg: yyyymmdd or yyyy-mm-dd!\n${thisusage}"
		    return 1
		fi
		case "${#}" in
		    1) echo -ne "${preview_mode}SELECT * FROM XRATES WHERE DT = '${dt}';\n" | "sqlite3" "${database_fn}";;
		    2)
			if _date -d "${1}" +%F &> /dev/null; then
			    echo -ne "${preview_mode}SELECT * FROM XRATES WHERE DT = '${dt}' AND FROM_CCY = '${2^^}';\n" | "sqlite3" "${database_fn}"
			else
			    echo -ne "${preview_mode}SELECT * FROM XRATES WHERE DT = '${dt}' AND FROM_CCY = '${1^^}' AND TO_CCY = '${2^^}';\n" | "sqlite3" "${database_fn}"
			fi;;
		    3) echo -ne "${preview_mode}SELECT * FROM XRATES WHERE DT = '${dt}' AND FROM_CCY = '${2^^}' AND TO_CCY = '${3^^}';\n" | "sqlite3" "${database_fn}";;

		esac
	    else
		log2err "${thisusage}"; return 1
	    fi
    esac
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "${@}"
