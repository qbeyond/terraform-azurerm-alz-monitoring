# Just apply all examples one after another

run "basic" {
    module {
        source = "./examples/basic"
    }
}

run "extra_queries" {
    module {
        source = "./examples/extra_queries"
    }
}

run "no_event_pipeline" {
    module {
        source = "./examples/no_event_pipeline"
    }
}