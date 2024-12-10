locals {
  active_directory = {
    "1008" = {
      area = "AD"
      severity = "critical"
      winsource = "Microsoft-Windows-ActiveDirectory_DomainService"
    }
    "1126" = {
      area = "AD"
      severity = "critical"
      winsource = "Microsoft-Windows-ActiveDirectory_DomainService"
    }
    "1567" = {
      area = "AD"
      severity = "critical"
      winsource = "Microsoft-Windows-ActiveDirectory_DomainService"
    }
  }
  managed_os = {
    "17137" = {
      area = "NT"
      severity = "Information"
      winsource = "MSSQL$EXPR_CM_530"
    } 
  }

  temp_test = templatefile("queries/windows_event.kusto.tftpl", {
            "all_events" = {
        "1008" = {
          "area"      = "AD"
          "severity"  = "critical"
          "winsource" = "Microsoft-Windows-ActiveDirectory_DomainService"
        }
        "17137" = {
          "area"      = "NT"
          "severity"  = "Information"
          "winsource" = "MSSQL$EXPR_CM_530"
      }}
    })
}