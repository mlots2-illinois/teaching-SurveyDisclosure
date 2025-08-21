# disclosure_check: Educational package for teaching survey disclosure avoidance

A comprehensive educational package that combines automated disclosure checking tools with teaching materials and a complete tutorial to help researchers understand and implement survey respondent privacy protection.

## 🎯 Overview

This package provides everything needed to understand and implement disclosure avoidance:
- **Automated tools** (`disclosure_check` and `check_implicit`) for identifying disclosure risks
- **Complete tutorial** with real survey data demonstrating best practices
- **Teaching materials** including presentation slides for workshops or self-study
- **Reference documentation** for implementing disclosure control in research projects

The tools implement the standard "Rule of Three" used in statistical disclosure control, automatically checking the data and warning when any group falls below safe thresholds. This is modifiable when the researcher/student calls the ado.

## 🚨 Why This Matters

When analyzing survey data, small cell counts can inadvertently identify individuals. For example, if your results show only one person over 65 with a PhD in the Engineering department, that person becomes identifiable. This creates serious issues:

- **Ethical violations** - Breaches research standards and respondent trust
- **Legal risks** - May violate privacy laws (GDPR, HIPAA, FERPA)
- **Publication barriers** - Journals may reject research with disclosure risks
- **Reputational damage** - Can harm your institution's credibility

## 📋 Features

### Tools & Automation
- ✅ Automatic detection of cells below threshold (default: 3)
- ✅ Support for complex cross-tabulations
- ✅ Implicit disclosure checking across subsamples
- ✅ Excel output with detailed suppression requirements
- ✅ Flexible threshold settings for sensitive variables

### Educational Materials
- 📚 Complete tutorial using Baylor Religion Survey data
- 🎓 Teaching presentation with learning outcomes and exercises
- 📝 Step-by-step workflow for disclosure avoidance
- 💡 Real-world examples and best practices
- 🔍 Practice exercises with solutions

### Learning Outcomes
After completing this package, you will be able to:
- Understand disclosure risk in survey data
- Identify potential disclosure risks in your research
- Use automated tools to check for disclosure risk
- Implement solutions when risks are identified
- Document your disclosure avoidance process
- Handle implicit samples and their risks

## 📁 Repository Structure

```
disclosure_check/
├── disclosure_check.ado              # Main disclosure checking program
├── check_implicit.ado                # Helper for implicit sample checks
├── Disclosure_Aug2025.pptx           # Editable presentation for workshops
├── Readme.md                        # Quick reference guide
└── Tutorial/                         
    ├── BaylorReligionSurvey_W5_Instructional_Dataset.dta 
    ├── BaylorReligionSurvey_W5_Instructional_Codebook.txt
    └── Tutorial.do                   # Complete worked example with real data
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
net install disclosure_check, from("https://github.com/mlots2-illinois/teaching-SurveyDisclosure/main")
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

## 📚 Tutorial & Teaching Materials

### Complete Tutorial Package
The tutorial uses real data from the Baylor Religion Survey Wave V (2017) to demonstrate disclosure avoidance in practice.

**Tutorial Contents:**
1. **Introduction to Disclosure Risk** - Understanding the triangle of risk
2. **Load and Explore Data** - Working with real survey data
3. **Establish Your Sample** - Creating analysis samples and model indicators
4. **Basic Disclosure Check** - Running your first disclosure check
5. **Religious Minorities** - Special considerations for small groups
6. **Continuous Variables** - Handling age and other continuous data
7. **Subsamples** - Creating and checking analysis subgroups
8. **Implicit Samples** - Understanding hidden disclosure risks
9. **Solutions** - Suppression, collapsing, and top-coding strategies
10. **Best Practices** - Complete workflow and documentation

### Teaching Presentation
The included presentation (`Disclosure_Aug2025.pptx`) covers:
- The triangle of risk concept
- Why the "Rule of Three" matters
- Statistical and privacy rationales
- Choosing appropriate thresholds
- Workflow for disclosure avoidance
- Implicit sample considerations
- Additional protection measures

### Practice Exercises
The tutorial includes hands-on exercises:
- Check disclosure risk for religious attendance by demographics
- Create college-educated subsample and check implicit risks
- Find and handle the smallest cell in your dataset
- Create publication-ready tables with proper suppression
- Automate disclosure checking for standard demographic tables

To run the complete tutorial:
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

## 🎓 For Instructors & Workshop Leaders

This package is designed for teaching disclosure avoidance concepts:

### Workshop Format
- **Duration**: 2-3 hours for complete coverage
- **Prerequisites**: Basic Stata knowledge
- **Materials**: All participants need Stata and the package files
- **Format**: Can be taught in-person or virtually

### Teaching Sequence
1. Start with the presentation to introduce concepts (30-45 min)
2. Walk through Tutorial sections 1-4 together (45 min)
3. Have participants work through sections 5-7 independently (30 min)
4. Reconvene to discuss implicit samples and solutions (30 min)
5. End with best practices and Q&A (15 min)

### Customization
- Presentation is provided in both PDF and PowerPoint formats
- Tutorial can be adapted for your specific dataset
- Threshold values can be adjusted for your field's standards
- Additional exercises can be added based on participant needs

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 📝 Citation

If you use this package in your research or teaching, please cite:
```
Lotspeich-Yadao, Michael (2025). disclosure_check: A Complete Educational Package for Survey Disclosure Avoidance in Stata. University of Illinois Urbana-Champaign. Available at: https://github.com/mlots2-illinois/teaching-SurveyDisclosure.
```

## 👤 Author

**Michael Lotspeich-Yadao**  
Research Assistant Professor  
College of Applied Health Sciences  
University of Illinois Urbana-Champaign  
Email: mlots2@illinois.edu

## 📚 Additional Resources

For more information on disclosure avoidance, see:
- **Federal Statistical System (FSS)** guidelines for disclosure of their member agencies.
- **National Academies Reports**:
  - "Private Lives and Public Policies: Confidentiality and Accessibility of Government Statistics"
  - "A Roadmap for Disclosure Avoidance in the Survey of Income and Program Participation"
  - "Toward a 21st Century National Data Infrastructure: Managing Privacy and Confidentiality Risks with Blended Data"

---

**Remember:** Protecting respondent privacy is not just a technical requirement—it's an ethical obligation that maintains trust in the research process. When in doubt, protect!
