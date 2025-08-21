# disclosure_check

**Protecting Survey Respondent Privacy in Stata**

A Stata package that automatically identifies disclosure risks in survey data to help researchers protect respondent privacy when sharing data or publishing results.

## 🎯 Overview

`disclosure_check` helps researchers identify when their data might accidentally reveal someone's identity, even without names or ID numbers. It implements the standard "Rule of Three" used in statistical disclosure control, automatically checking your data and warning when any group falls below safe thresholds.

## 🚨 Why This Matters

When analyzing survey data, small cell counts can inadvertently identify individuals. For example, if your results show only one person over 65 with a PhD in the Engineering department, that person becomes identifiable. This creates serious issues:

- **Ethical violations** - Breaches research standards and respondent trust
- **Legal risks** - May violate privacy laws (GDPR, HIPAA, FERPA)
- **Publication barriers** - Journals may reject research with disclosure risks
- **Reputational damage** - Can harm your institution's credibility

## 📋 Features

- ✅ Automatic detection of cells below threshold (default: 3)
- ✅ Support for complex cross-tabulations
- ✅ Implicit disclosure checking across subsamples
- ✅ Excel output with detailed suppression requirements
- ✅ Flexible threshold settings for sensitive variables
- ✅ Comprehensive tutorial with real survey data

## 📁 Repository Structure

```
disclosure_check/
├── disclosure_check.ado              # Main disclosure checking program
├── check_implicit.ado                # Helper for implicit sample checks
└── Tutorial/                         
    ├── BaylorReligionSurvey_W5_Instructional_Dataset.dta 
    ├── BaylorReligionSurvey_W5_Instructional_Codebook.txt
    └── Tutorial.do                   # Step-by-step tutorial
```

## 🚀 Installation

### Option 1: Direct Download
1. Download all `.ado` files to a local folder
2. Add the folder to Stata's adopath:
```stata
global disclosure_path "C:/path/to/disclosure_check"
adopath + "${disclosure_path}"
```

### Option 2: From GitHub
```stata
* Install directly from GitHub (if using git)
net install disclosure_check, from("https://raw.githubusercontent.com/[username]/disclosure_check/main")
```

### Option 3: Manual Installation
1. Clone or download this repository
2. Copy `.ado` files to your Stata personal ado folder
3. Type `sysdir` in Stata to find your personal folder location

## 💻 Quick Start

### Basic Usage
Check if any demographic groups are too small:
```stata
disclosure_check age gender race department, sample(my_survey) threshold(3)
```

### Check Multiple Variables
```stata
* Check demographics before publishing
disclosure_check gender race age education income, sample(main_survey) detail
```

### Custom Thresholds
```stata
* Use higher thresholds for sensitive data
disclosure_check mental_health substance_use, sample(health_survey) threshold(10)
```

## 📖 Examples

### Example 1: Publishing Demographics Table
```stata
* Before creating a demographics table
disclosure_check gender race age_group education, sample(survey2024) threshold(3)

* If issues found, the output will show which cells need suppression
```

### Example 2: Analyzing Subgroups
```stata
* Check a specific department
disclosure_check age gender race if department=="Engineering", sample(eng_dept)

* Also check for implicit disclosure in other departments
check_implicit, sample1(all_employees) sample2(eng_dept) varlist(age gender race)
```

### Example 3: Cross-tabulations
```stata
* Check religion by education (common disclosure risk)
disclosure_check religion education, sample(religious_survey) detail

* May need to combine small groups:
replace religion = "Other" if religion_count < 3
```

## 📊 Output

The package generates an Excel file with two sheets:

1. **Cell_Counts** - Detailed breakdown showing:
   - Variable combinations
   - Cell counts
   - Suppression requirements
   - Specific values needing attention

2. **Summary** - Overview including:
   - Check date and time
   - Threshold used
   - Overall pass/fail status
   - Number of cells requiring suppression

## 🛠️ Handling Disclosure Risks

When cells are too small, consider these strategies:

| Strategy | Description | Example |
|----------|-------------|---------|
| **Suppression** | Replace small counts with "suppressed" | Replace 1-2 with "<3" |
| **Combining** | Merge similar categories | "Other religions" instead of listing small groups |
| **Top/Bottom Coding** | Group extreme values | "80+ years" instead of exact ages |
| **Rounding** | Round to nearest 5 or 10 | Report "approximately 5" |
| **Ranges** | Report ranges instead of exact values | "fewer than 5" |

## 📚 Tutorial

The included tutorial uses real data from the Baylor Religion Survey to demonstrate:

- Basic disclosure checking
- Handling religious minorities in data
- Working with continuous variables (age, income)
- Cross-tabulation disclosure risks
- Geographic data considerations
- Creating publication-ready suppressed tables

To run the tutorial:
```stata
do "Tutorial/Tutorial.do"
```

## ⚙️ Syntax

### disclosure_check
```stata
disclosure_check varlist [if] [in], sample(string) [threshold(integer 3)] [detail] [export(string)]
```

**Parameters:**
- `varlist`: Variables to check for disclosure risk
- `sample`: Name identifier for this check
- `threshold`: Minimum acceptable cell size (default: 3)
- `detail`: Show detailed output in Stata console
- `export`: Custom path for Excel output

### check_implicit
```stata
check_implicit, sample1(string) sample2(string) varlist(varlist) [threshold(integer 3)]
```

**Parameters:**
- `sample1`: Full sample identifier
- `sample2`: Subsample identifier  
- `varlist`: Variables to check
- `threshold`: Minimum acceptable cell size (default: 3)

## ⚠️ Important Notes

- This package identifies risks but doesn't automatically fix them
- Always review output carefully before publication
- Consider your specific context and regulations
- Some fields may require higher thresholds (medical data: 5-10)
- Remember to check implicit disclosure across related analyses

## 📜 Disclaimer

While this package helps identify disclosure risks, researchers remain responsible for ensuring their data and publications meet all applicable privacy standards and regulations. When in doubt, consult with your institution's IRB or data protection officer.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 📝 Citation

If you use this package in your research, please cite:
```
[Citation information to be added]
```

## 📄 License

[License information to be added]

## 📧 Contact

[Contact information to be added]

## 🙏 Acknowledgments

- Tutorial data provided by the Baylor Religion Survey
- Inspired by best practices in statistical disclosure control

---

**Remember:** Protecting respondent privacy is not just a technical requirement—it's an ethical obligation that maintains trust in the research process.
