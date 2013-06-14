# Testing:
#
#  rake test:bundle       # Installs gems needed for the test apps (Bundle Install for each Rails app's Gemfile)
#  rake test:run          # Tests the gem's behavior, using 5 test rails apps of different versions, and random timeouts

namespace :test do

  TEST_RAILS_APP = [{ version: '3.0.3',     rails_root: 'test/test_apps/Test_3_0_3'},
                    { version: '3.0.20',    rails_root: 'test/test_apps/Test_3_0_20'},
                    { version: '3.1.12',    rails_root: 'test/test_apps/Test_3_1_12'},
                    { version: '3.2.13',    rails_root: 'test/test_apps/Test_3_2_13'},
                    { version: '4.0.0.rc1', rails_root: 'test/test_apps/Test_4_0_0_rc1'}]

  # Argument (env.):
  #    VERBOSE=t     Gives more information about what's going on
  #                  Other possible values (meaning the same): t, true, y, yes, on, ok
  #                  Default: no verbose (no flag)
  desc "Tests the gem's behavior, using 5 test rails apps of different versions, and random timeouts"
  task :run do
    # Verbose setting:
    verbose = boolean_env_param 'VERBOSE', 't', 'y', 'on', 'ok', 'yes', 'true'
    if verbose
      puts '------------------------------------------------'
      puts 'VERBOSE mode ON'
      print 'rvm setting (if rvm is being used): '
      system 'rvm current'
      puts "We'll run 5 times the test #1 (5 rails versions)"
      puts "Gem's ENV['BUNDLE_GEMFILE']='#{ENV['BUNDLE_GEMFILE']}'"
    end
    can_wait_bundle_gemfile = ENV['BUNDLE_GEMFILE']
    5.times do |num|
      puts "====TESTING Rails version #{TEST_RAILS_APP[num][:version]}================="
      if (TEST_RAILS_APP[num][:version] >= '4') && (RUBY_VERSION < '1.9.3')
        puts 'At least Ruby 1.9.3 is required for rails 4 or above...'
      else
        # Uses Gemfile for the given version of rails
        gemfile_path = escape_filename_spaces TEST_RAILS_APP[num][:rails_root]
        gemfile = gemfile_path<<'/Gemfile'
        ENV['BUNDLE_GEMFILE'] = gemfile
        if verbose
          puts "Gemfile to be used in this case (ENV['BUNDLE_GEMFILE']): '#{ENV['BUNDLE_GEMFILE']}'"
          print 'echo $BUNDLE_GEMFILE: '
          system 'echo $BUNDLE_GEMFILE'
        end
        # We check the Gemfile and bundle install:
        puts 'bundle check' if verbose
        if system("bundle check --gemfile='#{gemfile_path}' > /dev/null")
          if verbose
            puts "The Gemfile's dependencies are satisfied"
            puts 'Testing....'
          end
          # Run several timeouts test for that version of rails (bundle exec...)
          #   Only the last argument (V) is optional here:
          system "bundle exec ruby test/cant_wait_test.rb #{num} #{@gem_spec.version} #{'V' if verbose}"
        else
          puts ' bundle check and bundle failed! Check your rails test app Gemfile.'
          puts ' If there are missing gems, run rake test:bundle_apps'
        end
      end
    end
    puts '------------------------------------------------'
    ENV['BUNDLE_GEMFILE'] = can_wait_bundle_gemfile
    if verbose
      puts "Finally set again the gem ENV['BUNDLE_GEMFILE'] as:"
      puts "  '#{ENV['BUNDLE_GEMFILE']}'"
    end
  end

  # Arguments (env.):
  #   VERBOSE=t   It gives more information about what's going on
  #   REBUILD=t   It removes the Gemfile.lock, so it forces a clean bundle install
  #   Other possible values (meaning the same): t, true, y, yes, on, ok
  #   Default: no verbose, and no rebuild (no flags)
  # Example:
  #   $ rake test:bundle_apps REBUILD=y
  desc "Installs gems needed for the test apps (Bundle Install for each Rails app's Gemfile)"
  task :bundle do
    # Rebuild setting:
    rebuild = boolean_env_param 'REBUILD', 't', 'y', 'on', 'ok', 'yes', 'true'
    # Verbose setting:
    verbose = boolean_env_param 'VERBOSE', 't', 'y', 'on', 'ok', 'yes', 'true'
    if verbose
      puts "We'll bundle install for each of the 5 test rails apps"
      puts '============================================================'
      print '  rvm setting (if rvm is being used): '
      system 'rvm current'
      puts "  Gem's ENV['BUNDLE_GEMFILE']='#{ENV['BUNDLE_GEMFILE']}'" if verbose
    end
    can_wait_bundle_gemfile = ENV['BUNDLE_GEMFILE']
    initial_directory = FileUtils.pwd
    puts "  Initial task directory: #{initial_directory}" if verbose
    5.times do |num|
      if (TEST_RAILS_APP[num][:version] >= '4') && (RUBY_VERSION < '1.9.3')
        puts 'At least Ruby 1.9.3 is required for rails 4 or above...'
      else
        puts "====Rails app for Rails v. #{TEST_RAILS_APP[num][:version]}================"
        if verbose
          puts "  Present directory (pwd): #{FileUtils.pwd}"
          puts "  Changing to the app root..."
        end
        FileUtils.cd escape_filename_spaces TEST_RAILS_APP[num][:rails_root]
        puts "  Now present directory (pwd) is: #{FileUtils.pwd}" if verbose
        app_root = escape_filename_spaces FileUtils.pwd
        puts " App Root: #{app_root}" if verbose
        # Rebuilding the Gemfile.lock installs missing gems
        if rebuild
          puts 'Removing Gemfile.lock by installing any missing gems' if verbose
          FileUtils.rm 'Gemfile.lock' rescue nil
        end
        # Uses the Gemfile for the given version of rails
        ENV['BUNDLE_GEMFILE'] = 'Gemfile'
        puts "  Gemfile used in this case: (ENV['BUNDLE_GEMFILE']): '#{ENV['BUNDLE_GEMFILE']}'" if verbose
        # Bundle install this Gemfile:
        puts 'Bundle install failed! Check your rails test app' unless system('bundle')
        # Back to where we were:
        puts " Changing to the initial directory..." if verbose
        FileUtils.cd initial_directory
      end
    end
    puts '------------------------------------------------'
    ENV['BUNDLE_GEMFILE'] = can_wait_bundle_gemfile
    if verbose
      puts "Finally set again the gem ENV['BUNDLE_GEMFILE'] as:"
      puts "  '#{ENV['BUNDLE_GEMFILE']}'"
    end
  end

  private

  def escape_filename_spaces(filename)
    filename.gsub(' ', '\ ')
  end

end
