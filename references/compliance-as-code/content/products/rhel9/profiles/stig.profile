# RHEL 9 STIG Profile for ComplianceAsCode
# This is a representative stub. Replace with the full content from:
# https://github.com/ComplianceAsCode/content/tree/master/products/rhel9/profiles/stig.profile
#
# To retrieve the full profile, run:
#   scripts/baselines/sync-stig-baselines.sh

documentation_complete: true

title: 'DISA STIG for Red Hat Enterprise Linux 9'

description: |-
  This profile contains configuration checks that align to the
  DISA RHEL 9 STIG V1R6.

  In addition to technical OS hardening controls, this profile
  incorporates DoD policies for authentication, audit logging,
  and cryptographic protection consistent with JSIG requirements.

extends: ospp

selections:
  # Account Management
  - account_disable_post_pw_expiration
  - account_temp_expire_date
  - accounts_max_concurrent_login_sessions
  - accounts_password_set_max_life_existing
  - accounts_password_set_min_life_existing

  # Authentication & Passwords
  - no_empty_passwords
  - no_empty_passwords_etc_shadow
  - accounts_password_minlen_login_defs
  - accounts_passwords_pam_faillock_deny
  - accounts_passwords_pam_faillock_unlock_time
  - accounts_passwords_pam_faillock_interval

  # SSH Configuration
  - sshd_disable_root_login
  - sshd_disable_empty_passwords
  - sshd_set_max_auth_tries
  - sshd_set_idle_timeout
  - sshd_use_approved_macs
  - sshd_use_approved_ciphers

  # Audit & Logging
  - auditd_data_retention_max_log_file
  - auditd_data_retention_max_log_file_action
  - audit_rules_login_events
  - audit_rules_privileged_commands
  - audit_rules_networkconfig_modification
  - audit_rules_sysadmin_actions
  - service_auditd_enabled

  # FIPS
  - enable_fips_mode
  - grub2_enable_fips_mode

  # System Integrity
  - aide_build_database
  - aide_periodic_cron_checking

  # Kernel parameters
  - sysctl_kernel_dmesg_restrict
  - sysctl_kernel_randomize_va_space
  - sysctl_net_ipv4_ip_forward