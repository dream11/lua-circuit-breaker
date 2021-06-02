local configuration = {
	-- standard luacov configuration keys and values here
    runreport = true,
    reportfile = './luacov.report.out',

    -- multiple settings
    reporter = "multiple",

    multiple = {
        reporters = {"default", "multiple.cobertura"},
        cobertura = {
            reportfile = './cobertura.xml'
        }
    }
}
return configuration