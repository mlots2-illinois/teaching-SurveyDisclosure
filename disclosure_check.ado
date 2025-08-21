*! disclosure_check v1.1
*! Program to check disclosure risk and export cell counts for survey data
*! Author: Michael Lotspeich-Yadao, mlots2@illinois.edu
*! Date: 20250820
*! Enhancement: Captures cross-tabulation results in Excel output

capture program drop disclosure_check
program define disclosure_check, rclass
    version 14.0
    syntax varlist(fv) [if] [in], ///
        SAMPLEname(string) ///
        [OUTPUTfile(string)] ///
        [THRESHold(integer 3)] ///
        [DETail] ///
        [KEEPall] ///
        [NOLOg] ///
        [REPLACE]
    
    * Check if output file exists and handle replace option
    if "`outputfile'" == "" {
        local outputfile "disclosure_stats_`samplename'_$S_DATE.xlsx"
        * Clean filename
        local outputfile = subinstr("`outputfile'", " ", "_", .)
        local outputfile = subinstr("`outputfile'", ":", "", .)
    }
    
    if "`replace'" == "" {
        capture confirm file "`outputfile'"
        if _rc == 0 {
            display as error "File `outputfile' already exists. Use 'replace' option to overwrite."
            exit 602
        }
    }
    
    preserve
    
    * Apply if/in conditions
    marksample touse
    
    * Also restrict to sample variable if it exists
    capture confirm variable `samplename'
    if _rc == 0 {
        quietly replace `touse' = 0 if `samplename' != 1
        display as text "Restricting analysis to observations where `samplename' == 1"
    }
    
    keep if `touse'
    
    * Drop observations with missing values in any of the variables being checked
    foreach var of varlist `varlist' {
        quietly drop if missing(`var')
    }
    
    * Count observations after restrictions
    quietly count
    if r(N) == 0 {
        display as error "No observations remain after applying sample restriction and dropping missing values"
        restore
        exit 2000
    }
    
    * Count total observations
    quietly count
    local total_n = r(N)
    
    if `total_n' == 0 {
        display as error "No observations meet the specified conditions"
        restore
        exit 2000
    }
    
    * Initialize results matrices
    tempname results crosstab_results
    
    * Create temporary log file
    if "`nolog'" == "" {
        tempfile logfile
        quietly log using "`logfile'", text replace
    }
    
    display _newline(2)
    display "{hline 80}"
    display as result "DISCLOSURE AVOIDANCE CHECK REPORT"
    display as text "Sample: " as result "`samplename'"
    display as text "Date: " as result "$S_DATE $S_TIME"
    display as text "Total observations: " as result "`total_n'"
    display as text "Minimum cell threshold: " as result "`threshold'"
    display "{hline 80}"
    display _newline
    
    * Process each variable
    local var_num = 0
    local all_clear = 1
    local results_initialized = 0
    
    foreach var of varlist `varlist' {
        local var_num = `var_num' + 1
        
        display as text "Variable `var_num': " as result "`var'"
        display "{hline 40}"
        
        * Check variable type and process
        local check_var ""
        capture confirm numeric variable `var'
        if _rc == 0 {
            * Numeric variable
            quietly summarize `var', detail
            quietly levelsof `var' if !missing(`var'), local(levels)
            local n_levels : word count `levels'
            
            if `n_levels' > 20 {
                display as text "  Type: Continuous (categorized into quintiles)"
                tempvar var_cat
                quietly xtile `var_cat' = `var', nq(5)
                local check_var "`var_cat'"
                local var_label "Quintiles of `var'"
            }
            else {
                display as text "  Type: Categorical/Binary"
                local check_var "`var'"
                local var_label "`var'"
            }
        }
        else {
            * String variable
            display as text "  Type: String/Categorical"
            tempvar var_encoded
            encode `var', gen(`var_encoded')
            local check_var "`var_encoded'"
            local var_label "`var'"
        }
        
        * Get cell counts (excluding missing values explicitly)
        quietly tab `check_var' if !missing(`check_var'), matcell(cellcounts) matrow(rowvals)
        local n_cats = rowsof(cellcounts)
        
        display as text "  Number of categories: " as result "`n_cats'"
        display ""
        display as text "  {col 5}Category{col 20}Value/Label{col 45}Count{col 55}Status"
        display as text "  {hline 75}"
        
        * Check each cell
        local problem_cells = 0
        forvalues i = 1/`n_cats' {
            local val = rowvals[`i',1]
            local count = cellcounts[`i',1]
            
            * Get value label if exists
            local val_label : label (`check_var') `val'
            if "`val_label'" == "" {
                local val_label = "`val'"
            }
            
            * Truncate long labels
            if length("`val_label'") > 20 {
                local val_label = substr("`val_label'", 1, 17) + "..."
            }
            
            * Check against threshold
            if `count' < `threshold' & `count' > 0 {
                local status "SUPPRESS"
                local problem_cells = `problem_cells' + 1
                local all_clear = 0
                display as text "  {col 5}`i'{col 20}" ///
                    as result "`val_label'{col 45}" ///
                    as error "`count'{col 55}***`status'***"
            }
            else if `count' == 0 {
                local status "Empty"
                display as text "  {col 5}`i'{col 20}" ///
                    as result "`val_label'{col 45}" ///
                    as text "`count'{col 55}`status'"
            }
            else {
                local status "OK"
                display as text "  {col 5}`i'{col 20}" ///
                    as result "`val_label'{col 45}" ///
                    as text "`count'{col 55}`status'"
            }
            
            * Store results for Excel export
            if `results_initialized' == 0 {
                matrix `results' = (`var_num', `i', `val', `count', ///
                    (`count'<`threshold' & `count'>0))
                local results_initialized = 1
            }
            else {
                matrix `results' = `results' \ (`var_num', `i', `val', `count', ///
                    (`count'<`threshold' & `count'>0))
            }
        }
        
        if `problem_cells' > 0 {
            display ""
            display as error "  WARNING: `problem_cells' cell(s) below threshold!"
        }
        display _newline
    }
    
    * Check for cross-tabulations if requested
    local crosstab_initialized = 0
    if `: word count `varlist'' > 1 & "`detail'" != "" {
        display "{hline 80}"
        display as result "TWO-WAY CROSS-TABULATIONS CHECK"
        display "{hline 80}"
        display _newline
        
        * Final verification that no missing values exist
        display as text "Verifying no missing values before cross-tabulation:"
        foreach var of varlist `varlist' {
            quietly count if missing(`var')
            if r(N) > 0 {
                display as error "  ERROR: `var' still has `r(N)' missing values!"
            }
            else {
                display as text "  `var': No missing values ✓"
            }
        }
        display _newline
        
        local n_vars : word count `varlist'
        forvalues i = 1/`=`n_vars'-1' {
            forvalues j = `=`i'+1'/`n_vars' {
                local var1 : word `i' of `varlist'
                local var2 : word `j' of `varlist'
                
                display as text "Cross-tab: " as result "`var1' X `var2'"
                display "{hline 40}"
                
                * Double-check for missing values before cross-tab
                quietly count if missing(`var1') | missing(`var2')
                if r(N) > 0 {
                    display as error "  WARNING: Found `r(N)' observations with missing values in `var1' or `var2'"
                }
                
                * Create cross-tab and capture detailed results, excluding missing values
                quietly tab `var1' `var2' if !missing(`var1') & !missing(`var2'), matcell(crosstab) matrow(rowvals1) matcol(colvals1)
                local rows = rowsof(crosstab)
                local cols = colsof(crosstab)
                
                local problem_cells = 0
                local cross_results ""
                
                * Check each cell and store results
                forvalues r = 1/`rows' {
                    forvalues c = 1/`cols' {
                        local count = crosstab[`r',`c']
                        local row_val = rowvals1[`r',1]
                        local col_val = colvals1[`c',1]
                        
                        * Skip if either value is missing (shouldn't happen but safety check)
                        if `row_val' >= . | `col_val' >= . {
                            continue
                        }
                        
                        * Get value labels
                        local row_label : label (`var1') `row_val', strict
                        local col_label : label (`var2') `col_val', strict
                        if "`row_label'" == "" local row_label = "`row_val'"
                        if "`col_label'" == "" local col_label = "`col_val'"
                        
                        * Additional check - if labels come back as "." skip this cell
                        if "`row_label'" == "." | "`col_label'" == "." {
                            continue
                        }
                        
                        * Debug: Show what we're processing
                        if `count' < `threshold' & `count' > 0 {
                            display as text "    DEBUG: row_val=`row_val' (`row_label'), col_val=`col_val' (`col_label'), count=`count'"
                        }
                        
                        local suppress_flag = (`count' < `threshold' & `count' > 0)
                        
                        if `suppress_flag' {
                            local problem_cells = `problem_cells' + 1
                            display as text "    Cell [`row_label', `col_label']: " ///
                                as error "`count' ***SUPPRESS***"
                        }
                        
                        * Store cross-tab results (only for non-missing cells)
                        if `crosstab_initialized' == 0 {
                            matrix `crosstab_results' = (`i', `j', `r', `c', ///
                                `row_val', `col_val', `count', `suppress_flag')
                            local crosstab_initialized = 1
                        }
                        else {
                            matrix `crosstab_results' = `crosstab_results' \ ///
                                (`i', `j', `r', `c', `row_val', `col_val', ///
                                `count', `suppress_flag')
                        }
                    }
                }
                
                if `problem_cells' > 0 {
                    display as error "  WARNING: `problem_cells' cell(s) below threshold in cross-tab!"
                    local all_clear = 0
                }
                else {
                    display as text "  All cells meet threshold requirements"
                }
                display _newline
            }
        }
    }
    
    * Display summary
    display "{hline 80}"
    display as result "SUMMARY"
    display "{hline 80}"
    display ""
    display as text "Sample Name: " as result "`samplename'"
    display as text "Total Observations: " as result "`total_n'"
    display as text "Variables Checked: " as result "`: word count `varlist''"
    display as text "Minimum Cell Threshold: " as result "`threshold'"
    display ""
    
    if `all_clear' == 1 {
        display as result "STATUS: All cells meet disclosure requirements ✓"
    }
    else {
        display as error "STATUS: Some cells require suppression ✗"
        display as text "See detailed report for specific cells requiring suppression"
    }
    
    * Close log if using
    if "`nolog'" == "" {
        quietly log close
    }
    
    * Export to Excel
    quietly {
        * Export individual variable results
        clear
        if `results_initialized' == 1 {
            svmat `results'
            
            rename `results'1 variable_num
            rename `results'2 category_num
            rename `results'3 value
            rename `results'4 count
            rename `results'5 suppression_required
            
            * Add variable names
            gen variable_name = ""
            local var_num = 0
            tokenize `varlist'
            while "`1'" != "" {
                local var_num = `var_num' + 1
                replace variable_name = "`1'" if variable_num == `var_num'
                macro shift
            }
            
            * Add labels
            label variable variable_name "Variable Name"
            label variable category_num "Category Number"
            label variable value "Category Value"
            label variable count "Cell Count"
            label variable suppression_required "Requires Suppression (1=Yes)"
            
            * Order variables
            order variable_name variable_num category_num value count suppression_required
            
            * Export main results
            if "`replace'" != "" {
                export excel using "`outputfile'", ///
                    sheet("Individual_Variables") firstrow(varlabels) replace
            }
            else {
                export excel using "`outputfile'", ///
                    sheet("Individual_Variables") firstrow(varlabels)
            }
        }
        
        * Export cross-tabulation results if they exist
        if `crosstab_initialized' == 1 {
            clear
            svmat `crosstab_results'
            
            rename `crosstab_results'1 var1_num
            rename `crosstab_results'2 var2_num
            rename `crosstab_results'3 row_category
            rename `crosstab_results'4 col_category
            rename `crosstab_results'5 row_value
            rename `crosstab_results'6 col_value
            rename `crosstab_results'7 count
            rename `crosstab_results'8 suppression_required
            
            * Add variable names
            gen var1_name = ""
            gen var2_name = ""
            tokenize `varlist'
            local var_count = 1
            while "`1'" != "" {
                replace var1_name = "`1'" if var1_num == `var_count'
                replace var2_name = "`1'" if var2_num == `var_count'
                macro shift
                local var_count = `var_count' + 1
            }
            
            * Create cross-tab identifier
            gen crosstab_name = var1_name + " X " + var2_name
            
            * Add labels
            label variable crosstab_name "Cross-tabulation"
            label variable var1_name "Variable 1"
            label variable var2_name "Variable 2" 
            label variable row_value "Row Value"
            label variable col_value "Column Value"
            label variable count "Cell Count"
            label variable suppression_required "Requires Suppression (1=Yes)"
            
            * Order variables
            order crosstab_name var1_name var2_name row_value col_value count suppression_required
            
            * Export cross-tab results
            export excel using "`outputfile'", ///
                sheet("Cross_Tabulations") sheetmodify firstrow(varlabels)
        }
        
        * Create summary data
        clear
        set obs 1
        gen sample_name = "`samplename'"
        gen total_n = `total_n'
        gen threshold = `threshold'
        gen check_date = "$S_DATE $S_TIME"
        gen all_clear = `all_clear'
        gen variables_checked = "`: word count `varlist''"
        
        * Export summary (always modify since file now exists)
        export excel using "`outputfile'", ///
            sheet("Summary") sheetmodify firstrow(variables)
    }
    
    restore
    
    display _newline
    display as text "Results exported to: " as result "`outputfile'"
    display as text "Excel file contains three sheets:"
    display as text "  - Individual_Variables: Cell counts for each variable"
    display as text "  - Cross_Tabulations: Cross-tab results (if detail option used)"
    display as text "  - Summary: Overall check summary"
    display _newline
    
    * Return values
    return scalar N = `total_n'
    return scalar threshold = `threshold'
    return scalar all_clear = `all_clear'
    return local filename "`outputfile'"
    return local sample "`samplename'"
    
end
