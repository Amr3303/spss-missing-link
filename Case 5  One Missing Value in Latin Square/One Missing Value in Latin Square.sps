* Encoding: UTF-8.
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
        data.append([row[0], row[1], row[2], row[3]])  # Row, Column, Treatment, Value
    dataset.close()
    return data

def estimate_missing_value(data, p):
    """
    Estimate one missing value in a Latin Square design.
    
    Parameters:
    data -- list of lists where each inner list is [row, column, treatment, value]
    p -- number of rows/columns (since it's a square)
    
    Returns:
    estimated_value -- the estimated missing value
    """
    # Find the missing value position
    missing_row = None
    missing_col = None
    missing_tr = None
    
    for item in data:
        if item[3] is None:
            missing_row = int(item[0])
            missing_col = int(item[1])
            missing_tr = int(item[2])
            break
    
    if missing_row is None:
        return "No missing value found"
    
    # Calculate C (sum of values in the column with the missing value)
    C = sum(item[3] for item in data if item[0] == missing_row and item[3] is not None)
    print("C: ", {C})
    
    # Calculate R (sum of values in the row with the missing value)
    R = sum(item[3] for item in data if item[1] == missing_col and item[3] is not None)
    print("R: ", {R})
    
    # Calculate tr (sum of values in the treatment with the missing value)
    tr = sum(item[3] for item in data if item[2] == missing_tr and item[3] is not None)
    print("tr: ", {tr})
    
    # Calculate G (total sum of all values)
    G = sum(item[3] for item in data if item[3] is not None)
    print("G: ", {G})
    
    # Apply the formula: x_hat = (p(R+C+tr)-2G)/((p-1)(p-2))
    x_hat = (p * (R + C + tr) - 2 * G) / ((p - 1) * (p - 2))
    
    return x_hat

def main():
    data = load_data()
    print(data)
    
    estimated_value = estimate_missing_value(data, len(data[0]))
    
    if estimated_value is not None: 
        print("The estimated value = ", estimated_value)
    else:
        print("Unable to compute the missing value, boo hoo")

main()
END PROGRAM.

