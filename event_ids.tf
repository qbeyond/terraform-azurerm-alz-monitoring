locals {
  selected_events = merge(
    {},
    var.active_services.active_directory == true ? local.active_directory : {},
    var.active_services.managed_os == true ? local.managed_os : {},
    var.active_services.mssql == true ? local.mssql : {}
  )

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

    "517" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "Backup"
    }
    "1311" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "Microsoft-Windows-ActiveDirectory_DomainService"
    }
    "1312" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "Microsoft-Windows-ActiveDirectory_DomainService"
    }
    "1964" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "Microsoft-Windows-ActiveDirectory_DomainService"
    }
    "1977" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "Microsoft-Windows-ActiveDirectory_DomainService"
    }

    "5" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "SAM"
    }
    "6" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "SAM"
    }
    "7" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "SAM"
    }
    "10" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "SAM"
    }
    "11" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "SAM"
    }
    "13" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "SAM"
    }
    "14" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "SAM"
    }
    "15" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "SAM"
    }
    "16" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "SAM"
    }
    "18" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "SAM"
    }

    "4624" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "Microsoft-Windows-Security-Auditing"
    }

    "11150" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "DnsApi"
    }
    "11151" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "DnsApi"
    }
    "11152" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "DnsApi"
    }
    "11153" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "DnsApi"
    }
    "11155" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "DnsApi"
    }
    "11162" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "DnsApi"
    }
    "11163" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "DnsApi"
    }
    "11164" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "DnsApi"
    }
    "11165" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "DnsApi"
    }
    "11167" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "DnsApi"
    }

    "5" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "KDC"
    }
    "6" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "KDC"
    }
    "7" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "KDC"
    }
    "10" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "KDC"
    }
    "11" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "KDC"
    }
    "13" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "KDC"
    }
    "14" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "KDC"
    }
    "15" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "KDC"
    }
    "16" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "KDC"
    }
    "18" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "KDC"
    }
    "21" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "Win32Time"
    }
    "25" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "Win32Time"
    }
    "34" = {
      area      = "AD"
      severity  = "Warning"
      winsource = "Win32Time"
    }
  }

  managed_os = {
    "1003" = {
      area      = "NT"
      severity  = "Critical"
      winsource = "EventLog"
    }
    "6008" = {
      area      = "NT"
      severity  = "Critical"
      winsource = "EventLog"
    }
    "55" = {
      area      = "NT"
      severity  = "Critical"
      winsource = "Ntfs"
    }
    "10" = {
      area      = "NT"
      severity  = "Critical"
      winsource = "disk"
    }
    "2000" = {
      area      = "NT"
      severity  = "Critical"
      winsource = "srv"
    }

    "103" = {
      area      = "NT"
      severity  = "Warning"
      winsource = "Microsoft-Windows-TaskScheduler"
    }
    "202" = {
      area      = "NT"
      severity  = "Warning"
      winsource = "Microsoft-Windows-TaskScheduler"
    }
    "1500" = {
      area      = "NT"
      severity  = "Warning"
      winsource = "SNMP"
    }
    "4198" = {
      area      = "NT"
      severity  = "Warning"
      winsource = "Tcip"
    }
    "11" = {
      area      = "NT"
      severity  = "Warning"
      winsource = "disk"
    }
    "15" = {
      area      = "NT"
      severity  = "Warning"
      winsource = "disk"
    }
    "16" = {
      area      = "NT"
      severity  = "Warning"
      winsource = "mpio"
    }
    "32" = {
      area      = "NT"
      severity  = "Warning"
      winsource = "mpio"
    }
    "15" = {
      area      = "NT"
      severity  = "Warning"
      winsource = "symmpi"
    }
  }

  mssql = {
    "17061" = {
      area      = "MSSQL"
      severity  = "Warning"
      winsource = ""
    }
  }
}
