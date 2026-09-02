
#==============================================================================#

using ArgParse

# Automate the generation procedure from a single authoritative source.
include("test_suite_information.jl")

#===============================================================================
HANDLER
===============================================================================#

# CAUTION: Requires supporting the "--help" flag.
function verbose_handler(
	settings::ArgParseSettings, error::ArgParseError; exit_status::Int = 1
	)

	println(stderr, error.text)
	# Typically streams to standard output but this is an exception handler.
	redirect_stdout(stderr) do
		parse_args(["--help"], settings)
	end
	exit(exit_status)

end

#===============================================================================
GENERATORS
===============================================================================#

# CAUTION: Proper syntax for nested parametric typing.
@inline function enable_arg_table_generator(
	alternating_switch::Integer,
	info::Pair{
		<: Union{
			AbstractString,
			Base.AbstractVecOrTuple{<: AbstractString}
			},
		<: Tuple{Symbol, <: AbstractString}
		}
	)

	flag, (tag, help_text) = info
	return ifelse(
		isodd(alternating_switch),
		flag,
		Dict(
			:action => :store_const,
			:default => Symbol(),
			:constant => tag,
			:help => help_text
			)
		)

end

# CAUTION: Proper syntax for nested parametric typing.
@inline function disable_arg_table_generator(
	alternating_switch::Integer,
	info::Pair{
		<: Union{
			AbstractString,
			Base.AbstractVecOrTuple{<: AbstractString}
			},
		<: Tuple{Symbol, <: AbstractString}
		}
	)

	flag, (tag, help_text) = info
	return ifelse(
		isodd(alternating_switch),
		flag,
		Dict(
			:action => :store_const,
			:default => tag,
			:constant => Symbol(),
			:help => help_text
			)
		)

end

#===============================================================================
PARSING
===============================================================================#

# CAUTION: Proper syntax for nested parametric typing.
function query_enabled_tags(
	arguments::Base.AbstractVecOrTuple{<: AbstractString}
	)

	settings = ArgParseSettings()
	settings.description = "evaluate BitPackedInstances test suites"
	settings.usage = "usage: COMMAND"
	settings.exc_handler = verbose_handler
	# MUST provide PRECISELY one operation mode.
	add_arg_group!(
		settings, "operation modes:", "commands", true;
		exclusive = true, required = true
		)
	add_arg_table!(
		settings,
		"enable",
		Dict(
			:action => :command,
			:help => "enable the provided test suites (default: all)"
			),
		"disable",
		Dict(
			:action => :command,
			:help => "disable the provided test suites (default: none)"
			)
		)

	for (mode, default, generator_function) in (
		("enable", "(default: all)", enable_arg_table_generator),
		("disable", "(default: none)", disable_arg_table_generator)
		)

		current_settings = settings[mode]
		current_settings.description =
			mode * " evaluation of the provided test suites " * default
		current_settings.usage = "usage: " * mode * " [FLAGS]"
		current_settings.exc_handler = verbose_handler
		current_arg_table = (
			generator_function(n, i) for (n, i) in Base.Iterators.product(
				Base.OneTo(0x2), test_suite_information
				)
			)
		add_arg_table!(current_settings, current_arg_table...)

	end

	output = parse_args(arguments, settings)
	mode = output["%COMMAND%"]
	# Eliminate default sentinel value.
	enabled_tags = intersect(all_tags, values(output[mode]))
	# Enable all test suites if not explicitly specified.
	return ifelse(
		mode == "enable" && isempty(enabled_tags),
		all_tags,
		enabled_tags
		)

end

#==============================================================================#
