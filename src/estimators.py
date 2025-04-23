"""Core estimation algorithms for missing values in experimental designs.

This module contains implementations of various estimation methods for missing values
in different experimental design scenarios, including Two-Way ANOVA and Latin Square.
"""

def estimate_one_missing_value(data):
    """Estimate one missing value in a two-way ANOVA.
    
    Parameters:
    data -- list of lists where each inner list is [row, column, value]
    
    Returns:
    x_hat -- the estimated missing value
    missing_idx -- index of missing value in data
    missing_row -- row number of missing value
    missing_col -- column number of missing value
    """
    # Find the row and column with missing value
    missing_idx = None
    missing_row = None
    missing_col = None
    
    for i, item in enumerate(data):
        if item[2] is None:
            missing_idx = i
            missing_row = item[0]
            missing_col = item[1]
            break
    
    if missing_idx is None:
        return "Error: No missing value found"
    
    # Get the number of rows and columns
    rows = set(item[0] for item in data)
    columns = set(item[1] for item in data)
    r = len(rows)
    c = len(columns)
    
    # Calculate R (sum of values in the row with missing value)
    R = sum(item[2] for item in data if item[0] == missing_row and item[2] is not None)
    
    # Calculate C (sum of values in the column with missing value)
    C = sum(item[2] for item in data if item[1] == missing_col and item[2] is not None)
    
    # Calculate G (total sum of all values)
    G = sum(item[2] for item in data if item[2] is not None)
    
    # Apply the formula
    x_hat = (r * R + c * C - G) / ((r - 1) * (c - 1))
    
    return x_hat, missing_idx, missing_row, missing_col

def estimate_two_missing_values_same_row_diff_cols(data):
    """Estimate two missing values in the same row but different columns in a two-way ANOVA.
    
    Parameters:
    data -- list of lists where each inner list is [row, column, value]
    
    Returns:
    x1, x2 -- the estimated missing values
    missing_data -- information about missing value positions
    """
    # Find the row and columns with missing values
    missing_data = []
    for i, item in enumerate(data):
        if item[2] is None:
            missing_data.append((i, item[0], item[1]))
    
    if len(missing_data) != 2:
        return "Error: Expected exactly two missing values"
    
    # Check if missing values are in the same row
    if missing_data[0][1] != missing_data[1][1]:
        return "Error: Missing values must be in the same row"
    
    # Check if missing values are in different columns
    if missing_data[0][2] == missing_data[1][2]:
        return "Error: Missing values must be in different columns"
    
    # Get missing positions
    missing_row = missing_data[0][1]
    missing_cols = [item[2] for item in missing_data]
    
    # Get the number of rows and columns
    rows = set(item[0] for item in data)
    columns = set(item[1] for item in data)
    r = len(rows)
    c = len(columns)
    
    # Calculate R (sum of values in the row with missing values)
    R = sum(item[2] for item in data if item[0] == missing_row and item[2] is not None)
    
    # Calculate C1, C2 (sums of values in the columns with missing values)
    C1 = sum(item[2] for item in data if item[1] == missing_cols[0] and item[2] is not None)
    C2 = sum(item[2] for item in data if item[1] == missing_cols[1] and item[2] is not None)
    
    # Calculate G (total sum of all values)
    G = sum(item[2] for item in data if item[2] is not None)
    
    # Apply the formulas
    x1 = (r * R + (c - 1) * C1 + C2 - G) / ((r - 1) * (c - 2))
    x2 = (r * R + C1 + (c - 1) * C2 - G) / ((r - 1) * (c - 2))
    
    return x1, x2, missing_data

def estimate_two_missing_values_diff_rows_same_cols(data):
    """Estimate two missing values in different rows but the same column in a two-way ANOVA.
    
    Parameters:
    data -- list of lists where each inner list is [row, column, value]
    
    Returns:
    x1, x2 -- the estimated missing values
    missing_data -- information about missing value positions
    """
    # Find the rows and column with missing values
    missing_data = []
    for i, item in enumerate(data):
        if item[2] is None:
            missing_data.append((i, item[0], item[1]))
    
    if len(missing_data) != 2:
        return "Error: Expected exactly two missing values"
    
    # Check if missing values are in the same column
    if missing_data[0][2] != missing_data[1][2]:
        return "Error: Missing values must be in the same column"
    
    missing_column = missing_data[0][2]
    missing_rows = [item[1] for item in missing_data]
    
    # Get the number of rows and columns
    rows = set(item[0] for item in data)
    columns = set(item[1] for item in data)
    r = len(rows)
    c = len(columns)
    
    # Calculate C (sum of values in the column with missing values)
    C = sum(item[2] for item in data if item[1] == missing_column and item[2] is not None)
    
    # Calculate R1, R2 (sums of values in the rows with missing values)
    R1 = sum(item[2] for item in data if item[0] == missing_rows[0] and item[2] is not None)
    R2 = sum(item[2] for item in data if item[0] == missing_rows[1] and item[2] is not None)
    
    # Calculate G (total sum of all values)
    G = sum(item[2] for item in data if item[2] is not None)
    
    # Apply the formulas
    x1 = (c * R1 + (r - 1) * C + R2 - G) / ((r - 2) * (c - 1))
    x2 = (c * R2 + (r - 1) * C + R1 - G) / ((r - 2) * (c - 1))
    
    return x1, x2, missing_data

def estimate_two_missing_values_diff_rows_diff_cols(data):
    """Estimate two missing values in different rows and different columns in a two-way ANOVA.
    
    Parameters:
    data -- list of lists where each inner list is [row, column, value]
    
    Returns:
    x1, x2 -- the estimated missing values
    missing_data -- information about missing value positions
    """
    # Find the rows and columns with missing values
    missing_data = []
    for i, item in enumerate(data):
        if item[2] is None:
            missing_data.append((i, item[0], item[1]))
    
    if len(missing_data) != 2:
        return "Error: Expected exactly two missing values"
    
    # Check if missing values are in different rows and columns
    if missing_data[0][1] == missing_data[1][1]:
        return "Error: Missing values must be in different rows"
    if missing_data[0][2] == missing_data[1][2]:
        return "Error: Missing values must be in different columns"
    
    # Get missing positions
    missing_rows = [item[1] for item in missing_data]
    missing_cols = [item[2] for item in missing_data]
    
    # Get the number of rows and columns
    rows = set(item[0] for item in data)
    columns = set(item[1] for item in data)
    r = len(rows)
    c = len(columns)
    
    # Calculate R1, R2 (sums of values in the rows with missing values)
    R1 = sum(item[2] for item in data if item[0] == missing_rows[0] and item[2] is not None)
    R2 = sum(item[2] for item in data if item[0] == missing_rows[1] and item[2] is not None)
    
    # Calculate C1, C2 (sums of values in the columns with missing values)
    C1 = sum(item[2] for item in data if item[1] == missing_cols[0] and item[2] is not None)
    C2 = sum(item[2] for item in data if item[1] == missing_cols[1] and item[2] is not None)
    
    # Calculate G (total sum of all values)
    G = sum(item[2] for item in data if item[2] is not None)
    
    # Apply the formulas
    x1 = (c * R1 + r * C1 - G) / ((r - 1) * (c - 1))
    x2 = (c * R2 + r * C2 - G) / ((r - 1) * (c - 1))
    
    return x1, x2, missing_data