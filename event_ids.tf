locals {
  selected_events = merge({}, var.active_services.active_directory == true ? local.active_directory : {}, var.active_services.managed_os == true ? local.managed_os : {}, var.active_services.mssql == true ? local.mssql : {})

  active_directory = {
    "1008" = {
      area      = "AD"
      severity  = "critical"
      winsource = "Microsoft-Windows-ActiveDirectory_DomainService"
    }
    "1126" = {
      area      = "AD"
      severity  = "critical"
      winsource = "Microsoft-Windows-ActiveDirectory_DomainService"
    }
    "1567" = {
      area      = "AD"
      severity  = "critical"
      winsource = "Microsoft-Windows-ActiveDirectory_DomainService"
    }
  }

  managed_os = {
    "17137" = {
      area      = "NT"
      severity  = "Information"
      winsource = "MSSQL$EXPR_CM_530"
    }
  }

  mssql = {
    "17061" = {
      area      = "MSSQL"
      severity  = "Warning"
      winsource = " "
    }
  }
}
