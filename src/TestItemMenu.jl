module TestItemMenu

using REPL.TerminalMenus: RadioMenu, MultiSelectMenu, request

using TestItemRunner: find_testitems, run_testitems

function basic_test_menu(path; filter=nothing, verbose=true, menutype="radio")
    while true
        # find all test items
        package_name, testitems, testsetups = find_testitems(path; filter=filter)

        # prep testitems for the menu
        testitems_flatten = [
            ti for (_, _testitems) in pairs(testitems) for ti in _testitems
        ]
        # use naming convetion `filename::testitemname`
        testitems_names = map(ti -> "$(ti.filename)::$(ti.name)", testitems_flatten)
        # add the abort option
        pushfirst!(testitems_names, "abort")

        # create menu based on given type, returning if user didnt select anything
        verbose && println("============ Select tests! ===================")
        if menutype == "radio"
            menu = RadioMenu(testitems_names; pagesize=first(displaysize(stdout)) - 6)
            testitems_selections = request(menu)
            # fake it into a vector so its same format as if we instead used multiselect
            testitems_selections = [testitems_selections]
        elseif menutype == "multiselect"
            menu = MultiSelectMenu(testitems_names; pagesize=first(displaysize(stdout)) - 6)
            testitems_selections = collect(request(menu))
        elseif menutype == "test"
            # WARNING: this just for unit testing...
            testitems_selections = [1]
        else
            @warn "$menutype is not a valid menu type! Please choose from `radio` or `multiselect`"
            return nothing
        end

        # process user selection
        if testitems_selections == [] || testitems_selections == [-1]
            # blank selection
            verbose && println("==============================================\n\n")
            continue
        elseif testitems_selections == [1]
            # abort was only open chosen
            verbose && println("============ Exiting... ======================\n\n")
            return nothing
        end
        # if abort was chosen, remove it now
        testitems_selections = testitems_selections[testitems_selections .> 1]
        # offset because 'abort' was added
        testitems_selections .-= 1

        # recreate a dictionary in format required by TestItemRunner.run_tests(...)
        testitems_selections = testitems_flatten[testitems_selections]
        selected_files = Set(ti.filename for ti in testitems_selections)
        testitems = Dict([f => [] for f in selected_files])
        for ti in testitems_selections
            push!(testitems[ti.filename], ti)
        end

        # run tests
        run_testitems(path, package_name, testitems, testsetups; verbose=verbose)
        verbose && println("============ Tests complete! =================\n\n")
    end
end

end
