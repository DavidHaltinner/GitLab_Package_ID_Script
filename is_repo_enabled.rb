#!/usr/bin/env ruby

def check_git_lab_repo
# Check to ensure that the user's repository that GitLab was installed from,
# is still enabled.
# Note that if flatpak, snap, etc are ever used, this will need to be updated.

# If we are using a distribution that uses yum
if File.file?('/usr/bin/yum')
  # First determine if they installed gitlab-ce or gitlab-ee, and set the
  # eorce variable to the short package name for our use
  out = `rpm -qa gitlab-ce`
  eeorce = nil
  if out.include? 'gitlab-ce'
    eeorce = 'gitlab-ce'
  else
    out = `rpm -qa gitlab-ee`
    if out.include? 'gitlab-ee'
      eeorce = 'gitlab-ee'
    end
  end
  # If we did not find either with rpm, then they likely did not use a
  # package to install GitLab. Tell them, and return.
  if eeorce.nil?
    puts 'GitLab has determined that you have manually installed GitLab without'
    puts 'using a package.'
    puts 'We recommend using the official GitLab packages in the GitLab'
    puts 'repositories to ensure your installation remains up to date.'
    return
  end
  # Determine which repository was used to install GitLab
  out = `/usr/bin/yum -C list installed #{eeorce} 2>&1`
  repo = out.split.last[1..-1]
  if repo == 'installed' # Manually installed the package
    puts 'GitLab has determined that its package was not installed from a'
    puts 'repository.'
    puts 'We recommend using the official GitLab repositories to ensure your'
    puts 'installation remains up to date.'
  else # Repository was used, now we see if it is still enabled
    out = `/usr/bin/yum -C repolist enabled #{repo} 2>&1 | grep #{repo}`
    status = out.split.last
    if status.include? 'disabled' # Repository is disabled, so warn the user
      puts 'GitLab has discovered that the repository used to install GitLab'
      puts 'is currently disabled.'
      puts 'We recommend that you enable the repository to stay up to date on'
      puts 'the latest features and security updates.'
      return
    end
  end
# If they are using a distribution utilizing apt
elsif File.file?('/usr/bin/apt')
  # We need to determine if they are using gitlab-ce or gitlab-ee package
  `dpkg -s gitlab-ce 2>&1`
  success = $?
  eeorce = nil
  if success.to_i.zero?
    eeorce = 'gitlab-ce'
  else
    `dpkg -s gitlab-ee 2>&1`
    success = $?
    if success.to_i.zero?
      eeorce = 'gitlab-ee'
    end
  end
  # If neither packages show, they must have not used a package, so warn them
  # and return
  if eeorce.nil?
    puts 'GitLab has determined that you have manually installed GitLab without'
    puts 'using a package.'
    puts 'We recommend using the official GitLab packages in the GitLab'
    puts 'repositories to ensure your installation remains up to date.'
    return
  end
  # Check to see which repository it was installed from
  out = `apt show #{eeorce} 2>&1 | grep APT-Sources`
  repo = out.split(':')
  repo = "\"#{repo.last}\""
  # Extra new line is left hanging at the end in some instances
  repo.delete!("\n")
  # If the repo is shown as /var/lib/dpkg/status, that would mean the repository
  # is no longer installed
  if repo.include?('/var/lib/dpkg/status')
    puts 'GitLab has determined that the repository GitLab was installed from'
    puts 'is not enabled.'
    puts 'We recommend enabling the repository to ensure your installation'
    puts 'remains up to date.'
    return
  end
  # This will verify the repository is in the current policy, to ensure it
  # really is enabled
  `apt-cache policy | grep #{repo}`
  success = $?
  # if grep doesnt return 0, then the line wasnt found
  if success.to_i != 0 # This is more a catch-all, the if statement above
                  # 'should' see if the repo was not enabled.
    puts 'GitLab has determined that the repository GitLab was installed from'
    puts 'is not enabled, or its package was not installed manually and not'
    puts 'from a repository.'
    puts 'We recommend using the official GitLab repositories to ensure your'
    puts 'installation remains up to date.'
  end
# If they are using a distribution utilizing zypper
elsif File.file?('/usr/bin/zypper')
  # Check if they installed gitlab-ce or gitlab-ee, and set the eeorce variable
  #  to the short package name for our use
  out = `zypper --no-refresh info gitlab-ce | grep Name`
  eeorce = nil
  if out.include? 'gitlab-ce'
    eeorce = 'gitlab-ce'
  else
    out = `zypper --no-refresh info gitlab-ee | grep Name`
    if out.include? 'gitlab-ee'
      eeorce = 'gitlab-ee'
    end
  end
  # If we did not find either with zypper info, then they likely did not use a
  # package to install GitLab. Tell them, and return.
  if eeorce.nil?
    puts 'GitLab has determined that you have manually installed GitLab without'
    puts 'using a package.'
    puts 'We recommend using the official GitLab packages in the GitLab'
    puts 'repositories to ensure your installation remains up to date.'
    return
  end
  # Find the repository name
  out = `zypper --no-refresh info #{eeorce} | grep Repository`
  out = out.split(' ')
  repo = out.last
  # @System will mean the rpm was installed manually, or the repo isnt enabled
  # any longer
  if repo == "@System"
    puts 'GitLab has determined that its package was not installed from a'
    puts 'repository, or the repository is currently disabled.'
    puts 'We recommend enabling the repository, or using the official GitLab'
    puts 'repositories to ensure your installation remains up to date.'
    return
  end
  # Make sure that the repo is enabled in zypper
  out = `zypper repos #{repo} | grep Enabled`
  success = $?
  if success.to_i != 0
    puts 'GitLab has determined that the repository GitLab was installed from'
    puts 'is not enabled.'
    puts 'We recommend enabling the repository to ensure your installation'
    puts 'remains up to date.'
    return
  end
  out = out.split(' ')
  enabled = out.last
  # 'Should' nver get here, but just in case
  if enabled == 'No'
    puts 'GitLab has determined that the repository GitLab was installed from'
    puts 'is not enabled.'
    puts 'We recommend enabling the repository to ensure your installation'
    puts 'remains up to date.'
    return
  end
end
# If they dont use apt, yum, or zypper, it wont be an official package (likely
# arch, gentoo, slackware, or other), so we will do nothing in that case. They
# are on their own to ensure they keep up to date.
end

check_git_lab_repo
