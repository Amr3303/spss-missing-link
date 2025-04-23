# Missing Value Estimation for Experimental Designs

This project implements mathematical formulas for estimating missing values in various experimental design scenarios, specifically for Two-Way ANOVA and Latin Square designs. The implementation is done in Python and integrated with SPSS.

## Overview

Missing values in experimental designs can complicate statistical analysis. This project provides tools to estimate these missing values using established mathematical formulas, allowing researchers to proceed with their analysis with minimal disruption.

## Implemented Formulas

The project implements estimation formulas for the following scenarios:

1. **One Missing Value in Two-Way ANOVA**

   - Formula: $\hat{x} = \frac{rR+cC-G}{(r-1)(c-1)}$

   where:

   - $\hat{x}$ is the estimated missing value
   - $r$ is the number of rows
   - $c$ is the number of columns
   - $R$ is the sum of values in the row with the missing value
   - $C$ is the sum of values in the column with the missing value
   - $G$ is the total sum of all values

2. **Two Missing Values in Two-Way ANOVA (Same Row, Different Column)**

   - Formula for $\hat{x}_1$: $\frac{rR+(c-1)C_1+C_2-G}{(r-1)(c-2)}$
   <br>
   - Formula for $\hat{x}_2$: $\frac{rR+C_1+(c-1)C_2-G}{(r-1)(c-2)}$

   where:

   - $\hat{x}_1, \hat{x}_2$ are the estimated missing values
   - $r$ is the number of rows
   - $c$ is the number of columns
   - $R$ is the sum of values in the row with the missing values
   - $C_1, C_2$ are the sums of values in the columns with the missing values
   - $G$ is the total sum of all values

3. **Two Missing Values in Two-Way ANOVA (Different Row, Same Column)**

   - Formula for $\hat{x}_1$: $\frac{cC+(r-1)R_1+R_2-G}{(r-2)(c-1)}$
   <br>
   - Formula for $\hat{x}_2$: $\frac{cC+R_1+(r-1)R_2-G}{(r-2)(c-1)}$

   where:

   - $\hat{x}_1, \hat{x}_2$ are the estimated missing values
   - $r$ is the number of rows
   - $c$ is the number of columns
   - $C$ is the sum of values in the column with the missing values
   - $R_1, R_2$ are the sums of values in the rows with the missing values
   - $G$ is the total sum of all values

4. **Two Missing Values in Two-Way ANOVA (Different Row, Different Column)**

   - Formula for $\hat{x}_1$: $\frac{FW_1-W_2}{F^2-1}$
   <br>
   - Formula for $\hat{x}_2$: $\frac{FW_2-W_1}{F^2-1}$

   where:

   - $\hat{x}_1, \hat{x}_2$ are the estimated missing values
   - $F = (r-1)(c-1)$
   - $W_i = rR_i+cC_i-G$
   - $r$ is the number of rows
   - $c$ is the number of columns
   - $R_i$ is the sum of values in the row with the missing value $i$
   - $C_i$ is the sum of values in the column with the missing value $i$
   - $G$ is the total sum of all values

5. **One Missing Value in Latin Square Design**

   - Formula: $\hat{x} = \frac{p(R+C+tr)-2G}{(p-1)(p-2)}$

   where:

   - $\hat{x}$ is the estimated missing value
   - $p$ is the number of rows/columns (since it's a square)
   - $R$ is the sum of values in the row with the missing value
   - $C$ is the sum of values in the column with the missing value
   - $tr$ is the sum of values in the treatment (or additional factor)
   - $G$ is the total sum of all values

## Features

- Accurate implementation of mathematical formulas for missing value estimation
- Integration with SPSS for seamless workflow
- Support for various experimental design scenarios
- Easy-to-use Python functions for researchers without extensive programming knowledge

## Requirements

- SPSS with Python integration
- Python 3.4

## Usage

The package provides Python functions for each missing value scenario that can be called directly from SPSS. Example usage is provided in the documentation.

## Implementation Details

The implementation follows the mathematical formulas precisely to ensure accurate estimation of missing values. The code is structured to be easily understood and modified if necessary.

## Future Work

- Extend to other experimental designs
- Implement multiple missing values estimation for Latin Square designs
- Create a user-friendly interface for non-technical users

## References

- Statistical methods for handling missing data in experimental designs
- SPSS Python integration documentation
