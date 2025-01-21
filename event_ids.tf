locals {
  selected_events = concat(
    var.active_services.active_directory == true ? local.active_directory : [],
    var.active_services.managed_os == true ? local.managed_os : [],
    var.active_services.mssql == true ? local.mssql : []
  )

  active_directory = [
    {
      event_id  = "1008"
      area      = "AD"
      severity  = "critical"
      winsource = "Microsoft-Windows-ActiveDirectory_DomainService"
    },
    {
      event_id  = "1126"
      area      = "AD"
      severity  = "critical"
      winsource = "Microsoft-Windows-ActiveDirectory_DomainService"
    },
    {
      event_id  = "1567"
      area      = "AD"
      severity  = "critical"
      winsource = "Microsoft-Windows-ActiveDirectory_DomainService"
    },
    {
      event_id  = "517"
      area      = "AD"
      severity  = "Warning"
      winsource = "Backup"
    },
    {
      event_id  = "1311"
      area      = "AD"
      severity  = "Warning"
      winsource = "Microsoft-Windows-ActiveDirectory_DomainService"
    },
    {
      event_id  = "1312"
      area      = "AD"
      severity  = "Warning"
      winsource = "Microsoft-Windows-ActiveDirectory_DomainService"
    },
    {
      event_id  = "1964"
      area      = "AD"
      severity  = "Warning"
      winsource = "Microsoft-Windows-ActiveDirectory_DomainService"
    },
    {
      event_id  = "1977"
      area      = "AD"
      severity  = "Warning"
      winsource = "Microsoft-Windows-ActiveDirectory_DomainService"
    },

    {
      event_id  = "5"
      area      = "AD"
      severity  = "Warning"
      winsource = "SAM"
    },
    {
      event_id  = "6"
      area      = "AD"
      severity  = "Warning"
      winsource = "SAM"
    },
    {
      event_id  = "7"
      area      = "AD"
      severity  = "Warning"
      winsource = "SAM"
    },
    {
      event_id  = "10"
      area      = "AD"
      severity  = "Warning"
      winsource = "SAM"
    },
    {
      event_id  = "11"
      area      = "AD"
      severity  = "Warning"
      winsource = "SAM"
    },
    {
      event_id  = "13"
      area      = "AD"
      severity  = "Warning"
      winsource = "SAM"
    },
    {
      event_id  = "14"
      area      = "AD"
      severity  = "Warning"
      winsource = "SAM"
    },
    {
      event_id  = "15"
      area      = "AD"
      severity  = "Warning"
      winsource = "SAM"
    },
    {
      event_id  = "16"
      area      = "AD"
      severity  = "Warning"
      winsource = "SAM"
    },
    {
      event_id  = "18"
      area      = "AD"
      severity  = "Warning"
      winsource = "SAM"
    },

    {
      event_id  = "4624"
      area      = "AD"
      severity  = "Warning"
      winsource = "Microsoft-Windows-Security-Auditing"
    },

    {
      event_id  = "11150"
      area      = "AD"
      severity  = "Warning"
      winsource = "DnsApi"
    },
    {
      event_id  = "11151"
      area      = "AD"
      severity  = "Warning"
      winsource = "DnsApi"
    },
    {
      event_id  = "11152"
      area      = "AD"
      severity  = "Warning"
      winsource = "DnsApi"
    },
    {
      event_id  = "11153"
      area      = "AD"
      severity  = "Warning"
      winsource = "DnsApi"
    },
    {
      event_id  = "11155"
      area      = "AD"
      severity  = "Warning"
      winsource = "DnsApi"
    },
    {
      event_id  = "11162"
      area      = "AD"
      severity  = "Warning"
      winsource = "DnsApi"
    },
    {
      event_id  = "11163"
      area      = "AD"
      severity  = "Warning"
      winsource = "DnsApi"
    },
    {
      event_id  = "11164"
      area      = "AD"
      severity  = "Warning"
      winsource = "DnsApi"
    },
    {
      event_id  = "11165"
      area      = "AD"
      severity  = "Warning"
      winsource = "DnsApi"
    },
    {
      event_id  = "11167"
      area      = "AD"
      severity  = "Warning"
      winsource = "DnsApi"
    },

    {
      event_id  = "5"
      area      = "AD"
      severity  = "Warning"
      winsource = "KDC"
    },
    {
      event_id  = "6"
      area      = "AD"
      severity  = "Warning"
      winsource = "KDC"
    },
    {
      event_id  = "7"
      area      = "AD"
      severity  = "Warning"
      winsource = "KDC"
    },
    {
      event_id  = "10"
      area      = "AD"
      severity  = "Warning"
      winsource = "KDC"
    },
    {
      event_id  = "11"
      area      = "AD"
      severity  = "Warning"
      winsource = "KDC"
    },
    {
      event_id  = "13"
      area      = "AD"
      severity  = "Warning"
      winsource = "KDC"
    },
    {
      event_id  = "14"
      area      = "AD"
      severity  = "Warning"
      winsource = "KDC"
    },
    {
      event_id  = "15"
      area      = "AD"
      severity  = "Warning"
      winsource = "KDC"
    },
    {
      event_id  = "16"
      area      = "AD"
      severity  = "Warning"
      winsource = "KDC"
    },
    {
      event_id  = "18"
      area      = "AD"
      severity  = "Warning"
      winsource = "KDC"
    },
    {
      event_id  = "21"
      area      = "AD"
      severity  = "Warning"
      winsource = "Win32Time"
    },
    {
      event_id  = "25"
      area      = "AD"
      severity  = "Warning"
      winsource = "Win32Time"
    },
    {
      event_id  = "34"
      area      = "AD"
      severity  = "Warning"
      winsource = "Win32Time"
    }
  ]

  managed_os = [
    {
      event_id  = "1003"
      area      = "NT"
      severity  = "Critical"
      winsource = "EventLog"
    },
    {
      event_id  = "6008"
      area      = "NT"
      severity  = "Critical"
      winsource = "EventLog"
    },
    {
      event_id  = "55"
      area      = "NT"
      severity  = "Critical"
      winsource = "Ntfs"
    },
    {
      event_id  = "10"
      area      = "NT"
      severity  = "Critical"
      winsource = "disk"
    },
    {
      event_id  = "2000"
      area      = "NT"
      severity  = "Critical"
      winsource = "srv"
    },

    {
      event_id  = "103"
      area      = "NT"
      severity  = "Warning"
      winsource = "Microsoft-Windows-TaskScheduler"
    },
    {
      event_id  = "202"
      area      = "NT"
      severity  = "Warning"
      winsource = "Microsoft-Windows-TaskScheduler"
    },
    {
      event_id  = "1500"
      area      = "NT"
      severity  = "Warning"
      winsource = "SNMP"
    },
    {
      event_id  = "4198"
      area      = "NT"
      severity  = "Warning"
      winsource = "Tcip"
    },
    {
      event_id  = "11"
      area      = "NT"
      severity  = "Warning"
      winsource = "disk"
    },
    {
      event_id  = "15"
      area      = "NT"
      severity  = "Warning"
      winsource = "disk"
    },
    {
      event_id  = "16"
      area      = "NT"
      severity  = "Warning"
      winsource = "mpio"
    },
    {
      event_id  = "32"
      area      = "NT"
      severity  = "Warning"
      winsource = "mpio"
    },
    {
      event_id  = "15"
      area      = "NT"
      severity  = "Warning"
      winsource = "symmpi"
    }
  ]

  mssql = [
    {
      event_id  = "17061"
      area      = "MSSQL"
      severity  = "Warning"
      winsource = ""
    }
  ]
}
