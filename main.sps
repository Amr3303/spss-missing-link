﻿* Encoding: UTF-8.
SET PRINTBACK=NO.
BEGIN PROGRAM python3.
import spss
import spssdata


def long_to_wide(data):
    """Convert long format data to wide format."""
    # Step 1: Get all unique row and column labels
    row_labels = sorted(set(entry[0] for entry in data))  # Sort row labels numerically or lexicographically
    col_labels = sorted(set(entry[1] for entry in data))

    # Step 2: Create lookup dictionary for fast access
    lookup = {(row, col): val for row, col, val in data}

    # Step 3: Build wide-format list of lists
    wide_table = []
    for row in row_labels:
        row_data = []
        for col in col_labels:
            value = lookup.get((row, col), None)
            row_data.append(value)
        wide_table.append(row_data)
    
    return wide_table, row_labels, col_labels

def load_data():
    """Load data from SPSS into a Python list."""
    try:
        # First, try to determine the data structure by examining a sample
        dataset = spssdata.Spssdata()
        data = []
        
        # Read all rows into memory
        all_rows = []
        for row in dataset:
            all_rows.append(row)
        
        # Close the dataset
        dataset.close()
        
        # If we have data, determine the column count from the first row
        if all_rows:
            column_count = len(all_rows[0])
            
            # Process the data based on the column count
            for row in all_rows:
                if column_count == 3:  # Two-Way ANOVA format (row, column, value)
                    data.append([row[0], row[1], row[2]])
                elif column_count == 4:  # Latin Square format (row, column, treatment, value)
                    data.append([row[0], row[1], row[2], row[3]])
                else:
                    raise ValueError("Unexpected data format with %d columns" % column_count)
            
            return data
        else:
            print("No data found in SPSS dataset")
            return None
            
    except Exception as e:
        print("Error loading data: %s" % str(e))
        return None

def determine_data_structure(data):
    """
    Determine if the data is for Two-Way ANOVA or Latin Square design based on its structure.
    
    Returns:
    - "two_way_anova": If data has 3 columns (row, column, value)
    - "latin_square": If data has 4 columns (row, column, treatment, value)
    - "unknown": If the format doesn't match known patterns
    - The dimension of the design (number of rows/columns)
    """
    if not data or len(data) == 0:
        return "unknown", 0
    
    num_columns = len(data[0])
    
    if num_columns == 3:
        # Two-Way ANOVA format
        rows = len(set(item[0] for item in data))
        cols = len(set(item[1] for item in data))
        return "two_way_anova", rows, cols
    elif num_columns == 4:
        # Latin Square format - should be square
        rows = len(set(item[0] for item in data))
        cols = len(set(item[1] for item in data))
        treatments = len(set(item[2] for item in data))
        
        # Check if it's a true Latin Square (rows = cols = treatments)
        if rows == cols == treatments:
            return "latin_square", rows, cols
        else:
            print("Warning: Data appears to be Latin Square format but dimensions don't match: Rows=%d, Columns=%d, Treatments=%d" % (rows, cols, treatments))
            return "latin_square", rows, cols
    else:
        return "unknown", 0, 0

def detect_missing_pattern(data, data_structure):
    """
    Detect the pattern of missing values in the dataset.
    
    Parameters:
    - data: The dataset as a list of lists
    - data_structure: "two_way_anova" or "latin_square"
    
    Returns:
    - pattern_type: String describing the missing pattern
    - missing_positions: List of positions where values are missing
    """
    missing_count = 0
    missing_positions = []
    
    if data_structure == "two_way_anova":
        value_index = 2
        for i, item in enumerate(data):
            if item[value_index] is None:
                missing_count += 1
                missing_positions.append((i, item[0], item[1]))
                
        if missing_count == 0:
            return "no_missing", None
        elif missing_count == 1:
            return "one_missing", missing_positions
        elif missing_count == 2:
            # Check if missing values are in the same row
            if missing_positions[0][1] == missing_positions[1][1]:  # Same row
                if missing_positions[0][2] != missing_positions[1][2]:  # Different columns
                    return "two_missing_same_row", missing_positions
            # Check if missing values are in the same column
            elif missing_positions[0][2] == missing_positions[1][2]:  # Same column
                return "two_missing_same_column", missing_positions
            # Different rows and columns
            else:
                return "two_missing_diff_rows_diff_cols", missing_positions
        else:
            return "too_many_missing", missing_positions
            
    elif data_structure == "latin_square":
        value_index = 3
        for i, item in enumerate(data):
            if item[value_index] is None:
                missing_count += 1
                missing_positions.append((i, item[0], item[1], item[2]))
                
        if missing_count == 0:
            return "no_missing", None
        elif missing_count == 1:
            return "one_missing", missing_positions
        elif missing_count == 2:
            return "two_missing", missing_positions
        else:
            return "too_many_missing", missing_positions
            
    return "unknown", None

def estimate_one_missing_value_two_way_anova(data):
    """
    Estimate one missing value in a two-way ANOVA.
    
    Parameters:
    data -- list of lists where each inner list is [row, column, value]
    
    Returns:
    x_hat -- the estimated missing value
    """
    # Find the row and column with the missing value
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
    
    # Calculate R (sum of values in the row with the missing value)
    R = sum(item[2] for item in data if item[0] == missing_row and item[2] is not None)
    
    # Calculate C (sum of values in the column with the missing value)
    C = sum(item[2] for item in data if item[1] == missing_col and item[2] is not None)
    
    # Calculate G (total sum of all values)
    G = sum(item[2] for item in data if item[2] is not None)
    
    # Print intermediate values for verification
    print("r (number of rows):", r)
    print("c (number of columns):", c)
    print("R (sum of row " + str(missing_row) + "):", R)
    print("C (sum of column " + str(missing_col) + "):", C)
    print("G (total sum):", G)
    
    # Apply the formula
    x_hat = (r * R + c * C - G) / ((r - 1) * (c - 1))
    
    return x_hat, missing_idx, missing_row, missing_col

def estimate_two_missing_values_same_row_diff_cols(data):
    """
    Estimate two missing values in the same row but different columns in a two-way ANOVA.
    
    Parameters:
    data -- list of lists where each inner list is [row, column, value]
    
    Returns:
    x1, x2 -- the estimated missing values
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
    
    # Print intermediate values for verification
    print("r (number of rows):", r)
    print("c (number of columns):", c)
    print("R (sum of row " + str(missing_row) + "):", R)
    print("C1 (sum of column " + str(missing_cols[0]) + "):", C1)
    print("C2 (sum of column " + str(missing_cols[1]) + "):", C2)
    print("G (total sum):", G)
    
    # Apply the formulas
    x1 = (r * R + (c - 1) * C1 + C2 - G) / ((r - 1) * (c - 2))
    x2 = (r * R + C1 + (c - 1) * C2 - G) / ((r - 1) * (c - 2))
    
    return x1, x2, missing_data

def estimate_two_missing_values_diff_rows_same_cols(data):
    """
    Estimate two missing values in different rows but the same column in a two-way ANOVA.
    
    Parameters:
    data -- list of lists where each inner list is [row, column, value]
    
    Returns:
    x1, x2 -- the estimated missing values
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
    print("r (number of rows):", r)
    print("c (number of columns):", c)
    print("C (sum of column", missing_column, "):", C)
    print("R1 (sum of row", missing_rows[0], "):", R1)
    print("R2 (sum of row", missing_rows[1], "):", R2)
    print("G (total sum):", G)
    
    # Apply the formulas
    x1 = (c * C + (r - 1) * R1 + R2 - G) / ((r - 2) * (c - 1))
    x2 = (c * C + R1 + (r - 1) * R2 - G) / ((r - 2) * (c - 1))
    
    return x1, x2, missing_data

def estimate_two_missing_values_diff_rows_diff_cols(data):
    """
    Estimate two missing values in different rows and different columns in a two-way ANOVA.
    
    Parameters:
    data -- list of lists where each inner list is [row, column, value]
    
    Returns:
    x1, x2 -- the estimated missing values
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
    
    # Calculate F
    F = (r - 1) * (c - 1)
    
    # Calculate R1, R2 (sums of values in the rows with missing values)
    R1 = sum(item[2] for item in data if item[0] == missing_rows[0] and item[2] is not None)
    R2 = sum(item[2] for item in data if item[0] == missing_rows[1] and item[2] is not None)
    
    # Calculate C1, C2 (sums of values in the columns with missing values)
    C1 = sum(item[2] for item in data if item[1] == missing_cols[0] and item[2] is not None)
    C2 = sum(item[2] for item in data if item[1] == missing_cols[1] and item[2] is not None)
    
    # Calculate G (total sum of all values)
    G = sum(item[2] for item in data if item[2] is not None)
    
    # Calculate W1, W2
    W1 = r * R1 + c * C1 - G
    W2 = r * R2 + c * C2 - G
    
    # Print intermediate values for verification
    print("r (number of rows):", r)
    print("c (number of columns):", c)
    print("F:", F)
    print("R1 (sum of row " + str(missing_rows[0]) + "):", R1)
    print("R2 (sum of row " + str(missing_rows[1]) + "):", R2)
    print("C1 (sum of column " + str(missing_cols[0]) + "):", C1)
    print("C2 (sum of column " + str(missing_cols[1]) + "):", C2)
    print("G (total sum):", G)
    print("W1:", W1)
    print("W2:", W2)
    
    # Apply the formulas
    x1 = (F * W1 - W2) / (F * F - 1)
    x2 = (F * W2 - W1) / (F * F - 1)
    
    return x1, x2, missing_data

def estimate_missing_value_latin(data, p):
    """
    Estimate one missing value in a Latin Square design.
    
    Parameters:
    data -- list of lists where each inner list is [row, column, treatment, value]
    p -- number of rows/columns (since it's a Latin Square)
    
    Returns:
    estimated_value -- the estimated missing value
    """
    # Find the missing value position
    missing_idx = None
    missing_row = None
    missing_col = None
    missing_tr = None
    
    for i, item in enumerate(data):
        if item[3] is None:
            missing_idx = i
            missing_row = int(item[0])
            missing_col = int(item[1])
            missing_tr = int(item[2])
            break
    
    if missing_row is None:
        return "No missing value found"
    
    # Calculate R (sum of values in the row with the missing value)
    R = sum(item[3] for item in data if item[0] == missing_row and item[3] is not None)
    print("R (sum of row " + str(missing_row) + "):", R)
    
    # Calculate C (sum of values in the column with the missing value)
    C = sum(item[3] for item in data if item[1] == missing_col and item[3] is not None)
    print("C (sum of column " + str(missing_col) + "):", C)
    
    # Calculate tr (sum of values in the treatment with the missing value)
    tr = sum(item[3] for item in data if item[2] == missing_tr and item[3] is not None)
    print("tr (sum of treatment " + str(missing_tr) + "):", tr)
    
    # Calculate G (total sum of all values)
    G = sum(item[3] for item in data if item[3] is not None)
    print("G (total sum):", G)
    print("p (square size):", p)
    
    # Apply the formula: x_hat = (p(R+C+tr)-2G)/((p-1)(p-2))
    x_hat = (p * (R + C + tr) - 2 * G) / ((p - 1) * (p - 2))
    
    return x_hat, missing_idx, missing_row, missing_col, missing_tr

def estimate_two_missing_values_latin(data, p):
    """
    Estimate two missing values in a Latin Square design.
    
    Parameters:
    data -- list of lists where each inner list is [row, column, treatment, value]
    p -- number of rows/columns (since it's a Latin Square)
    
    Returns:
    x1, x2 -- the estimated missing values
    """
    # Find the positions of the two missing values
    missing_data = []
    for i, item in enumerate(data):
        if item[3] is None:
            missing_data.append((i, int(item[0]), int(item[1]), int(item[2])))
    
    if len(missing_data) != 2:
        return "Error: Expected exactly two missing values"
    
    # Unpack missing data
    idx1, row1, col1, tr1 = missing_data[0]
    idx2, row2, col2, tr2 = missing_data[1]
    
    # Calculate f = (r-1)(r-2) to simplify expressions
    f = (p - 1) * (p - 2)
    
    # Calculate G (total sum of all values)
    G = sum(item[3] for item in data if item[3] is not None)
    print("G (total sum):", G)
    
    # Calculate row totals excluding missing values
    R1 = sum(item[3] for item in data if item[0] == row1 and item[3] is not None)
    R2 = sum(item[3] for item in data if item[0] == row2 and item[3] is not None)
    
    # Calculate column totals excluding missing values
    C1 = sum(item[3] for item in data if item[1] == col1 and item[3] is not None)
    C2 = sum(item[3] for item in data if item[1] == col2 and item[3] is not None)
    
    # Calculate treatment totals excluding missing values
    T1 = sum(item[3] for item in data if item[2] == tr1 and item[3] is not None)
    T2 = sum(item[3] for item in data if item[2] == tr2 and item[3] is not None)
    
    # Print intermediate values for verification
    print("p (square size):", p)
    print("f = (p-1)(p-2):", f)
    print("R1 (sum of row " + str(row1) + "):", R1)
    print("R2 (sum of row " + str(row2) + "):", R2)
    print("C1 (sum of column " + str(col1) + "):", C1)
    print("C2 (sum of column " + str(col2) + "):", C2)
    print("T1 (sum of treatment " + str(tr1) + "):", T1)
    print("T2 (sum of treatment " + str(tr2) + "):", T2)
    
    # Determine which case we're dealing with
    if tr1 == tr2 and row1 != row2 and col1 != col2:
        print("Case I: Two missing values in the same treatment but different rows and columns")
        # Use T12 as the common treatment total
        T12 = T1  # or T2, they're the same
        
        # Calculate Q1 and Q2
        Q1 = p * (R1 + C1 + T12) - 2 * G
        Q2 = p * (R2 + C2 + T12) - 2 * G
        
        print("Q1:", Q1)
        print("Q2:", Q2)
        
        # Solve the system of equations
        # (f)y1 - (p-2)y2 = Q1
        # -(p-2)y1 + (f)y2 = Q2
        
        # Using Cramer's rule
        det = f * f - (p - 2) * (p - 2)
        y1 = (f * Q1 + (p - 2) * Q2) / det
        y2 = ((p - 2) * Q1 + f * Q2) / det
        
    elif row1 == row2 and col1 != col2 and tr1 != tr2:
        print("Case III: Two missing values in the same row but different columns and treatments")
        # Use R12 as the common row total
        R12 = R1  # or R2, they're the same
        
        # Calculate Q1 and Q2
        Q1 = p * (R12 + C1 + T1) - 2 * G
        Q2 = p * (R12 + C2 + T2) - 2 * G
        
        print("Q1:", Q1)
        print("Q2:", Q2)
        
        # Solve the system of equations (same structure as Case I)
        # (f)y1 - (p-2)y2 = Q1
        # -(p-2)y1 + (f)y2 = Q2
        
        # Using Cramer's rule
        det = f * f - (p - 2) * (p - 2)
        y1 = (f * Q1 + (p - 2) * Q2) / det
        y2 = ((p - 2) * Q1 + f * Q2) / det
        
    else:
        print("Case II: Missing values in different rows, columns, and treatments")
        # Calculate Q1 and Q2
        Q1 = p * (R1 + C1 + T1) - 2 * G
        Q2 = p * (R2 + C2 + T2) - 2 * G
        
        print("Q1:", Q1)
        print("Q2:", Q2)
        
        # Solve the system of equations
        # (f)y1 + 2y2 = Q1
        # 2y1 + (f)y2 = Q2
        
        # Direct solution
        f_squared_minus_4 = f * f - 4
        y1 = (f * Q1 - 2 * Q2) / f_squared_minus_4
        y2 = (f * Q2 - 2 * Q1) / f_squared_minus_4
    
    return y1, y2, missing_data

def process_data(data):
    """Main function to process the data based on its structure and missing value pattern."""
    if not data:
        print("No data to process.")
        return None
    
    # First determine the data structure
    data_structure, rows, cols = determine_data_structure(data)
    print("Detected data structure: %s with %d rows and %d columns" % (data_structure, rows, cols))
    
    if data_structure == "unknown":
        print("Error: Could not determine the data structure.")
        return data
    
    # Next detect missing pattern
    pattern, missing_positions = detect_missing_pattern(data, data_structure)
    print("Detected missing pattern: %s" % pattern)
    
    if pattern == "no_missing":
        print("No missing values found in the dataset.")
        return data
    
    if pattern == "too_many_missing":
        print("Error: Too many missing values. This script can handle at most two missing values for Two-Way ANOVA and two for Latin Square.")
        return data
    
    # Process based on the structure and pattern
    if data_structure == "two_way_anova":
        if pattern == "one_missing":
            result = estimate_one_missing_value_two_way_anova(data)
            if isinstance(result, tuple):
                x_hat, idx, row, col = result
                print("\nEstimated value for row %s and column %s: %.2f" % (row, col, x_hat))
                data[idx][2] = x_hat
                
        elif pattern == "two_missing_same_row":
            result = estimate_two_missing_values_same_row_diff_cols(data)
            if isinstance(result, tuple):
                x1, x2, missing_data = result
                print("\nEstimated values:")
                print("Row %s, Column %s: %.2f" % (missing_data[0][1], missing_data[0][2], x1))
                print("Row %s, Column %s: %.2f" % (missing_data[1][1], missing_data[1][2], x2))
                data[missing_data[0][0]][2] = x1
                data[missing_data[1][0]][2] = x2
                
        elif pattern == "two_missing_same_column":
            result = estimate_two_missing_values_diff_rows_same_cols(data)
            if isinstance(result, tuple):
                x1, x2, missing_data = result
                print("\nEstimated values:")
                print("Row %s, Column %s: %.2f" % (missing_data[0][1], missing_data[0][2], x1))
                print("Row %s, Column %s: %.2f" % (missing_data[1][1], missing_data[1][2], x2))
                data[missing_data[0][0]][2] = x1
                data[missing_data[1][0]][2] = x2
                
        elif pattern == "two_missing_diff_rows_diff_cols":
            result = estimate_two_missing_values_diff_rows_diff_cols(data)
            if isinstance(result, tuple):
                x1, x2, missing_data = result
                print("\nEstimated values:")
                print("Row %s, Column %s: %.2f" % (missing_data[0][1], missing_data[0][2], x1))
                print("Row %s, Column %s: %.2f" % (missing_data[1][1], missing_data[1][2], x2))
                data[missing_data[0][0]][2] = x1
                data[missing_data[1][0]][2] = x2
    
    elif data_structure == "latin_square":
        if pattern == "one_missing":
            # p is the size of the Latin Square (rows = cols = treatments)
            p = rows  # Since rows should equal cols in a Latin Square
            result = estimate_missing_value_latin(data, p)
            if isinstance(result, tuple):
                x_hat, idx, row, col, tr = result
                print("\nEstimated value for row %s, column %s, treatment %s: %.2f" % (row, col, tr, x_hat))
                data[idx][3] = x_hat
        elif pattern == "two_missing":
            # p is the size of the Latin Square
            p = rows
            result = estimate_two_missing_values_latin(data, p)
            if isinstance(result, tuple):
                y1, y2, missing_data = result
                print("\nEstimated values:")
                print("Row %s, Column %s, Treatment %s: %.2f" % (missing_data[0][1], missing_data[0][2], missing_data[0][3], y1))
                print("Row %s, Column %s, Treatment %s: %.2f" % (missing_data[1][1], missing_data[1][2], missing_data[1][3], y2))
                data[missing_data[0][0]][3] = y1
                data[missing_data[1][0]][3] = y2
    
    # Display the updated data
    print("\nUpdated data:")
    if data_structure == "latin_square":
        print("Row\tColumn\tTreatment\tValue")
        print("-" * 40)
        for row in data:
            print("%s\t%s\t%s\t\t%.2f" % (row[0], row[1], row[2], row[3]))
    else:  # Two-Way ANOVA
        print("Row\tColumn\tValue")
        print("-" * 30)
        for row in data:
            print("%s\t%s\t%.2f" % (row[0], row[1], row[2]))
    
    # Overwrite the data in SPSS
    spss.StartDataStep()
    dataset = spss.Dataset()
    cases = dataset.cases
    
    # Delete all existing cases
    while len(cases):
        del cases[0]
    
    # Insert the updated data
    for row in data:
        dataset.cases.insert(row)
    
    dataset.close()
    spss.EndDataStep()
    print("\nSPSS dataset has been updated with the estimated values.")
    
    return data

def main():
    """Main function to load data and process it."""
    try:
        print("Loading data...")
        data = load_data()
        print(data)
        
        if data:
            # Process the data
            updated_data = process_data(data)
            print("\nProcessing completed successfully.")
        else:
            print("Failed to load data. Exiting.")
            
    except Exception as e:
        print("Error: %s" % str(e))


main()

END PROGRAM.