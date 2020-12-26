# Hydraulics.jl
Standard piping hydraulic calculations
<!-- ABOUT THE PROJECT -->

## About The Project

This project provides functions in Julia for standard calculations for piping hydraulic calculations (line sizing and pressure drop calculation). The intention is to use the routines in a Jupyter Notebook file for documenting engineering work.  


### Built With

The code is written in Julia. The code is intended to be used in a Jupyter Notebook. I have not used the routines in a stand-alone Julia environment.

The user input is 


<!-- GETTING STARTED -->
## Getting Started

The following lines of code are needed in a Jupyter Notebook (Julia shell) to pull the package from GitHub and use the package.
~~~~
Pkg.add(PackageSpec(url="https://github.com/kevindorma/Hydraulics.js")
using Hydraulics.js
~~~~

### Prerequisites

The package requires the following packages
* DataFrames
* CSV
* ExcelFiles

<!-- TESTING -->
### Testing

The following code tests are available
* what tests do I need?
* pressure drop in a pipe.
* pressure drop in a fitting
* line sizing


<!-- USAGE EXAMPLES -->
## Usage

Refer to the Jupyter notebook file HydraulicsExample.ipynb for working examples.

A spreadsheet is very helpful for tabulating the input information.

Refer to the ./docs/src/index.md for documentation on functions.



<!-- ROADMAP -->
## Roadmap

See the [open issues](https://github.com/kevindorma/Hydraulics/issues) for a list of proposed features (and known issues).

* Build capability for network hydraulics.


<!-- CONTRIBUTING -->
## Contributing

Send me a note.



<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE` for more information.



<!-- CONTACT -->
## Contact

Kevin Dorma - [@KevinDorma](https://twitter.com/KevinDorma) - kevin@kevindorma.ca

Project Link: [https://github.com/kevindorma/Hydraulics](https://github.com/kevindorma/Hydraulics)



<!-- ACKNOWLEDGEMENTS -->
## Acknowledgements

Not sure who to acknowledge.
