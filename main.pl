use Data::Dumper;
use Time::HiRes "usleep";
use Time::gmtime;
use POSIX;
use Term::ReadKey;
use Storable "dclone";

package Console;
use Term::ReadKey;
use POSIX;

sub await_input {
  ReadMode 4;
  # I do not know why this works.
  # It was copied from some 20 year old website like 7 years ago.
  # All I know is it runs a while loop till the user presses a key.
  while (not defined ($that_key = ReadKey(-1))) {}
	# I know I just said I don't understand this code, but that was a
	# year or two ago. Anyways, here I check if the user pressed an
	# arrow key, then figure out if we should return an arrow key value.
	if (ord($that_key) eq 27) {
		ReadKey(-1);
		my $arrow_value = ord(ReadKey(-1));
		ReadMode 0;
		if ($arrow_value eq 65) {
			return "ARROW_UP";
		}
		if ($arrow_value eq 66) {
			return "ARROW_DOWN";
		}
		if ($arrow_value eq 67) {
			return "ARROW_RIGHT";
		}
		if ($arrow_value eq 68) {
			return "ARROW_LEFT";
		}
	}
  ReadMode 0;
  return $that_key;
}

sub blank_line {
  my $ender = Console::selected(" ");
  my $spaces = Console::width() - 4;
  print(" $ender");
  print(" " x $spaces);
  print("$ender ");
}

# Title,
sub check_menu {
  Console::clear();
  my $i = 0;
  my $selected = @_[1];
  # TODO: make this a menu with toggleable items.
}

sub clear {
  #system("clear");
}

sub debug_say {
  print($_[0]);
  Console::await_input();
}

sub just_line {
  my $result;
  for my $element (@_) {
    $result = "$result $element";
  }
  my $spaces = Console::width() - length($result);
  $spaces -= 5;
  my $ends = Console::selected(" ");
  print(" ");
  print("$ends $result");
  print(" " x $spaces);
  print("$ends \n");
}

sub lineup {
  my $result = "";
  for my $element (@_) {
    $result = "$result [ $element ] ";
  }
  my $spaces = Console::width() - (length($result) + 4);
  print(" ");
  print(Console::selected(" "));
  print($result);
  print(" " x $spaces);
  print(Console::selected(" "));
  print(" \n");
}

sub menu { # Title, selected, [options]
  Console::clear();
  my $i = 0;
  my $selected = @_[1];
  my $title = @_[0];
  print(Console::selected(" $title \n"));
  # For each argument past the second. -_-
  for my $arg (@_[2 .. $#_]) {
    if ($i eq $selected) {
      my $selected_portion = Console::selected("$arg \n");
      print(" - $selected_portion");
    } else {
      print(" - $arg \n");
    }
    $i++;
  }
  my $pressed = Console::await_input();
  if ($pressed eq "ARROW_UP") {
    $selected--;
    if ($selected lt 0) {$selected = 0;}
  } elsif ($pressed eq "ARROW_DOWN") {
    $selected++;
    if ($selected gt $#_ - 2) {$selected = $#_-2;}
  } elsif ($pressed eq "\n") {
    return $selected;
  } elsif ($pressed eq "q") {
    # Mostly for debug.
		exit();
  }
  return Console::menu(@_[0], $selected, @_[2 .. $#_]);
}

sub read_with_title {
  my $title = $_[0];
  my $header = Console::selected("$title");
  print("$header\n:");
  my $result = <STDIN>;
  chomp($result);
  return $result;
}

sub selected {
  return "\e[30m\e[107m$_[0]\e[0m";
}

sub width {
  my $size = `stty size`;
  my @size_split = split(" ", $size);
  return $size_split[1];
}

package Config;
use JSON;
use Data::Dumper;
my $filename = "FDTimer.json";
my @default_categories = (
  "3x3x3",
  "2x2x2",
  "4x4x4",
  "Skewb",
  "Pyraminx",
  "Square-1"
);

sub create {
  my $default_option = Console::menu(
    "Would you like to use the defaults? (Most WCA cubes)",
    0,
    "Yes",
    "No, view/change defaults"
  );
  if ($default_option eq 1) {
    Config::edit_default();
  }

  my %json_data;
  for my $category (@default_categories) {
    @{$json_data{"times"}{"$category"}} = ();
  }
  my $string = encode_json(\%json_data);
  open(WRITABLE, ">", $filename) or die $!;
  print(WRITABLE $string);
  close(WRITABLE) or die $!;
}

sub edit_default {
  my $going = 1;
  while ($going) {
    my $selection = Console::menu(
      "Select one to delete, or create a new one.",
      0,
      "Create new",
      "Done",
      @default_categories
    );
    if ($selection eq 0) {
      my $new_one = Console::read_with_title("Enter new name");
      push(@default_categories, $new_one);
    } elsif ($selection eq 1) {
      $going = 0;
    } else {
      splice(@default_categories, $selection - 2, 1);
    }
  }
}

sub load {
  if (not -e $filename) {
    Config::prompt_creaion();
  }
  print("Reading config file...");
  open(READER, "<", $filename);
  my $string = join("", <READER>);
  close(READER);
  my $data = decode_json($string);
  return $data;
}

sub prompt_creaion {
  my $selection = Console::menu(
    "The config file ($config_name) doesn't appear to exist yet. Create it now?",
    0,
    "Yes",
    "No, exit now"
  );
  if ($selection eq 0) {
    Config::create();
  } else {
    exit();
  }
}

sub save {
  my $string = encode_json($_[0]) or die ($!);
  Console::clear();
  print("Saving config file...\n");
  open(WRITABLE, ">", $filename);
  print(WRITABLE $string);
  close(WRITABLE);
}


package main;
use POSIX;
use Scalar::Util "looks_like_number";
sub usage {
  print("Run:
  perl FDTimer.pl
to start the program. I tried to make the interface pretty self explanitory.
Command line arguments:
  --manual-time <Category> <Minutes:Seconds> - Manuallpy add a time to <Category> in the
    config file.


  ");
}

if (@ARGV[0]) {
  my $flag = @ARGV[0];
  if ($flag eq "--help") {
    usage();
  } elsif ($flag eq "--test-things") {
   	print(unformat_time(@ARGV[1]));
  } elsif ($flag eq "--manual-time") {
    manual_time_cli(@ARGV[1], @ARGV[2]);
  } else {
    print("Unknown flag: $flag\n");
  }
	exit();
}

# This will get solve data if it exists, or prompt creation if not.
my $data = dclone Config::load();
my $current_category;

sub average {
  my $all = 0;
  for my $number (@_) {
    $all += $number;
  }
  if ($#_ eq 0) {return 0;}
  return $all / $#_;
}

sub create_category {
  Console::clear();
  my $name = Console::read_with_title("Enter new category name. Leave blank to cancel.");
  if ($name) {
    print("$name");
    @{$data-> {"times"}-> {"$name"}} = ();
    $current_category = $name;
  }
}

# I know there's probably a better way to do this, I don't wanna hear it.
sub format_time {
  my $ms = floor($_[0] * 1000);
	if ($ms eq 0) {
		return "--";
	}
  my $seconds = ($ms / 1000) % 60;
  my $minutes = floor(($ms / 1000) / 60) or "00";
  my $rms = $ms % 6000;

  return "$minutes:$seconds.$rms";
}

sub get_best_time { # Supply arg of 1 to force search.
  if ($data-> {"best_times"}-> {"$current_category"} and not $_[0]) {
    return $data-> {"best_times"}-> {"$current_category"};
  }
  my @times = $data-> {"times"}-> {"$current_category"};
  my $best = @times[0];
  for my $time (@times) {
    if ($time lt $best) {
      $best = $time;
    }
  }
  $data-> {"best_times"}-> {"$current_category"} = $best;
  return $best;
}

sub get_last_time {
  my $times = $data-> {"times"}-> {"$current_category"};
  my $times_length = @$times;
  if ($times->[0] eq "") {
    return "No data";
  } else {
    return $times-> [$times_length - 1];
  }
}

sub get_recent_times {
  my @times = @{$data-> {"times"}-> {"$current_category"}};
  return @times[($#times - $_[0]) .. $#times];
}

sub manual_time_cli {
  my $data = dclone Config::load();
	my $seconds = unformat_time($_[1]);
	if ($seconds eq -1) {
		# looks_like_number returned 0.
		print("$_[0] does not look like a number or time. Exiting.\n");
	}
  push(@{$data-> {"times"}-> {"$_[0]"}}, $seconds);
  Config::save($data);
  exit();
}

sub options {
  my $selection = Console::menu(
    "What would you like to do?",
    0,
    "Delete a time",
    "Manually add a time",
    "Edit settings"
  );
  if ($selection eq 0) {
    select_delete_time();
  }
}

# Supply time, 1 to not wait for an event.
sub render {
  Console::clear();

  my $time = $_[0];

  # Title header. Don't ask me how it works, I just tweaked the numbers till it looked ok.
  my $title = " Fever Dream's cube timer";
  my $spaces = Console::width() - length($title);
  $spaces -= 5;
  if ($spaces lt 0) {
    die("Your console is too narrow. Dear god.");
  }
  print(" \e[30m\e[107m $title");
  print(" " x $spaces);
  print("  \e[0m\n");
  Console::blank_line();

  # Current time
  my $best = format_time(get_best_time());
  Console::lineup("$time");

  # Category, Best time
  Console::lineup("$current_category; C to change", "Current best: $best");
  Console::blank_line();

  # Recent times
  my @last5 = get_recent_times(5);
  my $ao5;
  if (not $#last5) {
    $ao5 = "--";
  } else {
    $ao5 = average(@last5);
  }
  Console::lineup("+ Recent times: -", "Ao5: $ao5");
  for my $last (@last5) {
    my $formatted = format_time($last);
    Console::just_line(" | $formatted");
  }
  Console::blank_line();

  # Controls
  my @controls = (
    "Space: Start timer",
    "Q: Quit",
    "O: Options"
  );
  my $full_controls;
  for my $control (@controls) {
    $full_controls = "$full_controls [ $control ] ";
  }
  my $spaces = Console::width() - length($full_controls);
  $spaces -= 2;
  print(" \e[30m\e[107m$full_controls");
  print(" " x $spaces);
  print("\e[0m");

  if ($_[1]) {
    return;
  }

  my $event = Console::await_input();
  if ($event eq "q") {
    Config::save($data);
    exit();
  } elsif ($event eq " ") {
    start_inspection();
  } elsif ($event eq "c") {
    select_category();
    render($_[0]);
  } elsif ($event eq "o") {
    options();
  } else {
    render($_[0]);
  }
}

sub remove_category {
  my @options = keys(%{$data->{"times"}});
  my $selection = Console::menu(
    "Select a category to remove",
    0,
    "(Cancel)",
    @options
  );
  if ($selection eq 0) {
    return;
  }
  my $selected_category = $options[$selection - 1];
	delete($data-> {"times"}-> {$selected_category});
	delete($data-> {"best_times"}-> {$selected_category});
}

sub report_best {
  render("New best! $_[0]", 1);
	$data-> {"best_times"}-> {"$current_category"} = $_[0];
  sleep(3);
}

sub select_delete_time {
	my @options = @{$data-> {"times"}-> {"$current_category"}};
	# So we're showing more recent times first.
	@options = reverse(@options);
	my $selection;
	my $done = 0;
	my $page = 0;
	while (not $done) {
		$selection = Console::menu(
			"Select a time to delete",
			0,
			"(Cancel)",
			@options[$page .. $page + 10],
			"(More)"
		);
		if ($selection eq 0) {
			return;
		}
	}
}

sub select_category {
  my @options = keys(%{$data->{"times"}});
  my $selected = Console::menu(
    "Select category",
    0,
    "(Create new)",
    "(Remove a category)",
    @options
  );
  if ($selected eq 0) {
    create_category();
    return;
  } if ($selected eq 1) {
    remove_category();
    select_category();
  }
  $current_category = $options[$selected - 2];
}

sub start_inspection {
  my $time = 15;
  ReadMode 4;
  my $key;
  while ($time gt 0 && not defined($key = ReadKey(-1))) {
    if (index("$time", ".") eq -1 ) {
      render($time, 1);
    }
    usleep(10000);
    $time -= 0.01;
  }
  if ($key eq "\e") {
    render("Cancelled");
    return;
  }
  if (not $time lt 0.01) {
    start_timer();
  } else {
    render("No more inspection time.");
  }
}

sub start_timer {
  render("Timing. Escape to DNF, or any other key to stop.", 1);
  my $recorded_time = 0;
  while (not defined($key = ReadKey(-1))) {
    usleep(10000);
    $recorded_time += 0.01;
  }
  if ($key eq "\e") {
    render("DNF");
    return;
  }

  my %time_data = (
    "time" => $recorded_time,
    "date"
  );
  push(@{$data->{"times"}->{"$current_category"}}, $recorded_time);
  my $current_best = $data-> {"best_times"}-> {"$current_category"} or get_best_time();
  if ($recorded_time lt $current_best) {
    report_best($recorded_time);
  }
  render(format_time($recorded_time));
}

sub unformat_time {
	# If it's already just the amount of seconds.
	if (index($_[0], ":") == -1) {
		# Make sure it's a number.
		return -1 if not looks_like_number($_[0]);
		return $_[0];
	}
	my @split = split(/:/, $_[0]);
	# Make sure we ended up with numbers.
	return -1 if (not looks_like_number($split[0])) or (not looks_like_number($split[1]));
	my $seconds = 0;
	$seconds += $split[1];
	$seconds += $split[0] * 60;
	return $seconds;
}

select_category();
render(format_time(get_last_time()), 0);
