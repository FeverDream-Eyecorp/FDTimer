use Data::Dumper;
use Time::HiRes "usleep";
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
  ReadMode 0;
  return $that_key;
}

sub blank_line {
  my $ender = Console::selected("|");
  my $spaces = Console::width() - 4;
  print(" $ender");
  print(" " x $spaces);
  print("$ender ");
}

sub clear {
  system("clear");
}

sub debug_say {
  print($_[0]);
  Console::await_input();
}

sub lineup {
  my $result = "";
  for my $element (@_) {
    $result = "$result [ $element ] ";
  }
  my $spaces = Console::width() - (length($result) + 4);
  print(" ");
  print(Console::selected("|"));
  print($result);
  print(" " x $spaces);
  print(Console::selected("|"));
  print(" \n");
}

sub menu { # Title, selected, [options]
  Console::clear();
  my $i = 0;
  my $selected = @_[1];
  my $title = "@_[0] (W, S to move, Enter to select.)";
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
  if ($pressed eq "w") {
    $selected--;
    if ($selected lt 0) {$selected = 0;}
  } elsif ($pressed eq "s") {
    $selected++;
    if ($selected gt $#_ - 2) {$selected = $#_-2;}
  } elsif ($pressed eq "\n") {
    return $selected;
  } elsif ($pressed eq "q") {
    # Mostly for debug. If I forget to close a loop or something I don't wanna be
    # trapped and have to killall perl, since PERL WON'T LET ME USE CTRL+C FOR
    # SOME STUPID FUCKING REASON!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
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
    @json_data{"$category"} = [];
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
sub usage {
  print("");
}

if (@ARGV[0] eq "--help") {
  usage();
  exit();
} elsif (@ARGV[0] eq "--test-things") {
  print(format_time("Hello world"));
  exit();
}

# This will get solve data if it exists, or prompt creation if not.
my $data = dclone Config::load();
my $current_category;

sub create_category {
  Console::clear();
  my $name = Console::read_with_title("Enter new category name. Leave blank to cancel.");
  if ($name) {
    print("$name");
    @{$data->{"$name"}} = [];
  }
}

# I know there's probably a better way to do this, I don't wanna hear it.
sub format_time {
  my $f = $_[0];
  my $minutes = 0;
  my $seconds;
  my $point_seconds_1 =  $f - floor($f);
  my $point_seconds = substr("$point_seconds_1", 2, 2);
  if ($f gt 60) {
    $minutes = floor($f / 60);
    $seconds = $f % 60;
  } else {
    $seconds = floor($f);
  }
  if (length("$seconds") lt 2) {
    $seconds = "0$seconds";
  }
  return "$minutes:$seconds.$point_seconds";
}

sub get_last_time {
  my $times = $data-> {"$current_category"};
  my $times_length = @$times;
  if ($times->[0] eq "") {
    return "No data";
  } else {
    return $times-> [$times_length - 1];
  }
}

# Supply time, 1 to not wait for an event.
sub render {
  Console::clear();

  my $time = $_[0];

  # Title header. Don't ask me how it works, I just tweaked the numbers till it looked ok.
  my $title = "Fever Dream's cube timer";
  my $spaces = Console::width() - length($title);
  $spaces -= 5;
  if ($spaces lt 0) {
    die("Your console is too narrow. Oh god.");
  }
  print(" \e[30m\e[107m[ $title");
  print(" " x $spaces);
  print("]\e[0m\n");

  # Category, current time.
  Console::lineup("$current_category; C to change", $time);

  Console::blank_line();

  # Controls
  my @controls = (
    "Space: Start timer",
    "C: Select category",
    "Q: Quit"
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
  } else {
    render($_[0]);
  }
}

sub select_category {
  my @options = keys(%{$data});
  my $selected = Console::menu(
    "Select category",
    0,
    "Create new",
    @options
  );
  if ($selected eq 0) {
    create_category();
    return;
  }
  $current_category = $options[$selected - 1];
}

sub start_inspection {
  my $time = 15;
  ReadMode 4;
  my $key;
  while ($time gt 0 && not defined($key = ReadKey(-1))) {
    sleep(1);
    $time -= 1;
    render($time, 1);
  }
  if ($time eq 0) {
    render("No more inspection time.");
  } else {
    start_timer();
  }
}

sub start_timer {
  render("Timing. Escape to DNF, or any other key to stop.", 1);
  my $recorded_time = 0;
  while (not defined($key = ReadKey(-1))) {
    usleep(10000);
    $recorded_time += 0.01;
  }
  Console::debug_say("$key");
  my @times = $data->{"$current_category"};
  push(@{$data->{"$current_category"}}, $recorded_time);
  render(format_time($recorded_time));
}

select_category();
render(format_time(get_last_time()), 0);
