# disclosure_check - Protecting Survey Respondent Privacy in Stata

## What is this?

`disclosure_check` is a Stata package that helps researchers protect the privacy of survey respondents when sharing data or publishing results. It automatically identifies when your data might accidentally reveal someone's identity, even without names or ID numbers.

## Why is this important?

Imagine you're analyzing a workplace survey. If your results show there's only one person over 65 with a PhD in the Engineering department, anyone could figure out who that person is. This is called **disclosure risk**, and it's a serious privacy concern that:

- Violates ethical research standards
- May break privacy laws (GDPR, HIPAA, etc.)
- Breaches respondent trust
- Could get your research rejected by journals

## The "Rule of Three"

The standard practice in research is to never report data for groups with fewer than 3 people. This package automatically checks your data and warns you when any group falls below this threshold (or any threshold you set).

## What's included?

```
disclosure_check/
├── disclosure_check.ado     		# Main program that checks for disclosure risk
├── check_implicit.ado       		# Helper program for checking implicit samples
└── Tutorial                 		
	├── BaylorReligionSurvey_W5_Instructional_Dataset.dta 
	├── BaylorReligionSurvey_W5_Instructional_Codebook.txt
	└── Tutorial.do
```

## Installation

1. Download all files to a folder on your computer
2. In Stata, tell it where to find the files:
```stata
global disclosure_path "C:/path/to/your/disclosure_check_folder"
adopath + "${disclosure_path}"
```
3. That's it! You can now use the commands.

## Quick Start

Basic usage to check if any demographic groups are too small:
```stata
disclosure_check age gender race department, sample(my_survey) threshold(3)
```

This will:
- Check each variable for cells with fewer than 3 people
- Flag any problematic combinations
- Export results to an Excel file
- Show you exactly what needs to be fixed

## Real-World Example

Let's say you want to publish a table showing religion by education level:

```stata
* Check if any religion×education combination has too few people
disclosure_check religion education, sample(religious_survey) detail

* If problems are found, you might need to:
* 1. Combine small religious groups into "Other"
* 2. Collapse education categories (e.g., "Graduate degree" instead of "PhD" and "Masters" separately)
* 3. Report "fewer than 3" instead of exact numbers
```

## Common Scenarios

### Publishing Demographics
Before publishing any demographic table:
```stata
disclosure_check gender race age education, sample(main_survey) threshold(3)
```

### Working with Subgroups
When analyzing just one department:
```stata
* Check the department you're analyzing
disclosure_check age gender race if department=="Engineering", sample(engineering)

* Don't forget to check if other departments become identifiable!
check_implicit, sample1(all_staff) sample2(engineering) varlist(age gender race)
```

### Sensitive Variables
For especially sensitive data, use a higher threshold:
```stata
disclosure_check mental_health substance_use income, sample(health_survey) threshold(10)
```

## What to do when cells are too small?

The package identifies problems; you need to fix them by:

1. **Suppressing**: Replace small numbers with "suppressed" or missing
2. **Combining categories**: Merge similar groups (e.g., multiple small religions into "Other")
3. **Top/bottom coding**: For age, group everyone 80+ together
4. **Reporting ranges**: Say "fewer than 5" instead of exact counts

## Tutorial

The included `Tutorial.do` file walks through a complete analysis using real survey data (Baylor Religion Survey). It covers:
- Basic disclosure checking
- Handling religious minorities
- Working with age and continuous variables
- Cross-tabulation risks
- Geographic considerations
- Creating publication-ready tables

Run it section by section to learn best practices!

## Output

The package creates an Excel file with two sheets:
1. **Cell_Counts**: Detailed list of every cell count and suppression requirements
2. **Summary**: Overview of the check including date, threshold, and overall status

## Disclaimer

While this package helps identify disclosure risks, researchers remain responsible for ensuring their data and publications meet all applicable privacy standards and regulations. When in doubt, consult with your institution's IRB or data protection officer.