clear all
//cd "C:/Users/thoma/OneDrive/Work/Projects/School Finance"


// GET FRED CPI DATA (STATE AND LOCAL EXPENDITURES)
set fredkey ec503200f5f87be7fcb6ad2fdf3dd025
import fred A829RD3A086NBEA, daterange(1994-01-01 2019-01-01) clear

rename A829RD3A086NBEA index_

gen year = year(daten)

// Take average of two consecutive years to correspond to school year
gen index = (index_[_n] + index_[_n-1]) / 2 if !missing(index_[_n-1])

replace index = (index * 100) / 113.9925 // Set 2019 as reference year
drop if year == 1994 | year > 2017

keeporder year index

tempfile cpi
save `cpi'


// IMPORT REVENUE BY STATE DATASET
import delimited "Data Raw/Revenue by State.csv", clear

// RESHAPE DATASET
reshape long pupils total_rev_nom local_rev_nom state_rev_nom fed_rev_nom, ///
  i(state) j(year)

// MERGE IN CPI DATA
merge m:1 year using `cpi', nogen

// CLEAN DATA

// Replace $0 revenues
replace state_rev_nom = . if state_rev_nom == 0

// Adjust for inflation
foreach x in total_rev local_rev state_rev fed_rev {
  gen `x'_real = `x'_nom / (index / 100)
}

// Convert to per pupil revenue
foreach x in total_rev local_rev state_rev fed_rev {
  gen `x' = round(`x'_real / pupils, 1)
}

// RANK REVENUE BY YEAR
foreach var of varlist total_rev local_rev state_rev fed_rev {
  bys year: gegen `var'_rank = rank(`var'), field
}

// KEEP & ORDER VARIABLES
keeporder state year total_rev local_rev state_rev fed_rev total_rev_rank ///
  local_rev_rank state_rev_rank fed_rev_rank

// LABEL VARIABLES

// Variable labels
label var state "State"
label var year "School year"
label var total_rev "Total revenue"
label var local_rev "Local revenue"
label var state_rev "State revenue"
label var fed_rev "Federal revenue"
label var total_rev_rank "Total revenue rank"
label var local_rev_rank "Local revenue rank"
label var state_rev_rank "State revenue rank"
label var fed_rev_rank "Federal revenue rank"

// SORT AND SAVE
sort state year
compress
save "Data Derived/Revenue by State.dta", replace

// EXPORT TOTAL REVENUE TO CSV
export delimited state year total_rev using "Data Derived/total_rev.csv", ///
  replace
