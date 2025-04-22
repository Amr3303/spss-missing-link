SET PRINTBACK=NO.
BEGIN PROGRAM.
import spss
import spssdata

def load_data():
    """
    Loads the data set from SPSS, store it in a list of lists
    """
    dataset = spssdata.Spssdata()
    data = []
    for row in dataset:
        data.append([row[0], row[1], row[2]])  # Row, Column, Value
    dataset.close()
    return data

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


def main():
    data = load_data()
    print("Original data:", data)
    print("\n\n\n")

    x_hat1, x_hat2, missing_data = estimate_two_missing_values_same_row_diff_cols(data)

    if x_hat1 is not None and x_hat2 is not None:
        print("\nEstimated value for the row: {} and column: {} = {:.2f}".format(
            int(missing_data[0][1]), int(missing_data[0][2]), x_hat1))
        print("Estimated value for the row: {} and column: {} = {:.2f}".format(
            int(missing_data[1][1]), int(missing_data[1][2]), x_hat2))
        
        # Update the values in our data list
        for i, item in enumerate(data):
            if item[0] == missing_data[0][1] and item[1] == missing_data[0][2]:
                data[i][2] = x_hat1
            elif item[0] == missing_data[1][1] and item[1] == missing_data[1][2]:
                data[i][2] = x_hat2
        
        # Convert the data back to SPSS format using DO IF commands
        spss_commands = []
        # For first missing value (row II, column A)
        spss_commands.append("DO IF ($CASENUM = 5).")  # Case 5 corresponds to II A
        spss_commands.append("COMPUTE value = {:.4f}.".format(x_hat1))
        spss_commands.append("END IF.")
        # For second missing value (row II, column C)
        spss_commands.append("DO IF ($CASENUM = 7).")  # Case 7 corresponds to II C
        spss_commands.append("COMPUTE value = {:.4f}.".format(x_hat2))
        spss_commands.append("END IF.")
        spss_commands.append("EXECUTE.")
        
        # Execute all commands at once
        for cmd in spss_commands:
            spss.Submit(cmd)
            
        print("\nComplete dataset has been updated with estimated values.")
    else:
        print("Unable to compute the missing values, boo hoo")

main()

END PROGRAM.

