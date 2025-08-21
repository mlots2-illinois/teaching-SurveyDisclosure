*! check_implicit v1.1
*! Check for implicit samples between two samples
*! Fixed: Corrected sample size calculations

capture program drop check_implicit
program define check_implicit, rclass
    version 14.0
    syntax, SAMPLE1(varname) SAMPLE2(varname) ///
        [VARlist(varlist)] ///
        [THRESHold(integer 3)]
    
    display _newline
    display "{hline 60}"
    display as result "IMPLICIT SAMPLE CHECK"
    display "{hline 60}"
    
    preserve
    
    * Get actual sample counts
    quietly count if `sample1' == 1
    local sample1_n = r(N)
    
    quietly count if `sample2' == 1 
    local sample2_n = r(N)
    
    * Identify implicit sample (in sample1 but not in sample2)
    tempvar implicit
    gen `implicit' = `sample1' == 1 & `sample2' == 0
    
    quietly count if `implicit' == 1
    local implicit_n = r(N)
    
    display as text "Sample 1 observations: " as result %9.0f `sample1_n'
    display as text "Sample 2 observations: " as result %9.0f `sample2_n'
    display as text "Implicit sample size: " as result %9.0f `implicit_n'
    
    if `implicit_n' < `threshold' & `implicit_n' > 0 {
        display _newline
        display as error "WARNING: Implicit sample below minimum threshold (`threshold')!"
        display as error "This creates a disclosure risk that must be addressed."
    }
    else if `implicit_n' == 0 {
        display _newline
        display as text "No implicit sample exists (Sample 2 contains all of Sample 1)"
    }
    else {
        display _newline
        display as result "Implicit sample meets minimum threshold ✓"
    }
    
    * Check variables in implicit sample if specified
    if "`varlist'" != "" & `implicit_n' > 0 {
        display _newline
        display as text "Variable checks in implicit sample:"
        display "{hline 40}"
        
        foreach var of varlist `varlist' {
            quietly tab `var' if `implicit' == 1
            local n_cats = r(r)
            local n_obs = r(N)
            
            display as text "  `var': " as result "`n_obs' obs in `n_cats' categories"
            
            * Check for small cells
            quietly tab `var' if `implicit' == 1, matcell(cells)
            local problem = 0
            forvalues i = 1/`n_cats' {
                if cells[`i',1] < `threshold' & cells[`i',1] > 0 {
                    local problem = 1
                }
            }
            if `problem' == 1 {
                display as error "    WARNING: Some categories below threshold"
            }
        }
    }
    
    restore
    
    * Return values
    return scalar sample1_n = `sample1_n'
    return scalar sample2_n = `sample2_n'
    return scalar implicit_n = `implicit_n'
    return scalar threshold_met = (`implicit_n' >= `threshold' | `implicit_n' == 0)
    
end