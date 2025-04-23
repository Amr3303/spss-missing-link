SET PRINTBACK=NO.
BEGIN PROGRAM python3.

data = [
    [1, 1, 3.00],
    [1, 2, 4.20],
    [1, 3, 2.50],
    [1, 4, 3.50],
    [2, 1, 4.00],
    [2, 3, 2444]
]

def main():
    import spss, spssdata
    from spss import Dataset

    # getting the all the variable names
    variable_names = []
    i = 0
    while True:
        try:
            var_name = spss.GetVariableName(i)
            variable_names.append(var_name)
            i += 1
        except:
            break
    print("All the variable names: ", variable_names)

    # Start a data step so we can modify the active dataset
    spss.StartDataStep()    
    dataset = Dataset()    
    cases = dataset.cases              
    
    # --- Delete all existing cases ---
    while len(cases):
        del cases[0]                   

    # --- Appeding all existing data ---
    for row in data:
        print(row)
        dataset.cases.insert(row)      

    dataset.close()

    # End the data step
    spss.EndDataStep()
    print("\nDataset has been updated.")
    
main()

END PROGRAM.