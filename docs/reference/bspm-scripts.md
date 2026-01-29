# Call Internal Scripts

Internal scripts can be called via `Rscript` (see examples).

## Examples

    if (FALSE) { # \dontrun{
    # get a list of available scripts with descriptions
    Rscript -e bspm:::scripts

    # see a script's help
    Rscript -e bspm:::scripts <script_name> -h

    # run a script
    Rscript -e bspm:::scripts <script_name> [args]
    } # }
