"""Data loading utilities for SPSS data files.

This module provides functions for loading and preprocessing data from SPSS files
for use with the estimation algorithms.
"""

import spss
import spssdata

def load_data():
    """Load data from SPSS into a list of lists format.
    
    Returns:
    list -- A list of lists where each inner list contains [row, column, value]
    """
    dataset = spssdata.Spssdata()
    data = []
    for row in dataset:
        data.append([row[0], row[1], row[2]])  # Row, Column, Value
    dataset.close()
    return data

def update_spss_data(missing_data, estimated_values):
    """Update SPSS dataset with estimated values.
    
    Parameters:
    missing_data -- List of tuples containing (index, row, column) for missing values
    estimated_values -- List of estimated values to insert
    """
    for (idx, _, _), value in zip(missing_data, estimated_values):
        # Select the case
        spss.Submit(f"SELECT IF $CASENUM = {idx + 1}.")
        # Update the value
        spss.Submit(f"COMPUTE value = {value}.")
        spss.Submit("EXECUTE.")
    
    # Reset case selection
    spss.Submit("SELECT IF $CASENUM > 0.")
    spss.Submit("EXECUTE.")