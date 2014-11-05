Description
===========

imos_core includes most one line (or more) short recipes we have here at IMOS:
 * email_forward - Email forwards for root
 * lftp - Installs lftp program
 * logrotate - Default log rotation
 * lvm - Installs the logical volume manager
 * motd - Message of the day (/etc/motd)
 * ncftp - Installs ncftp program

Requirements
============

Attributes
==========

### email_forward
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>[:email_forward][:email_address]</tt></td>
    <td>String</td>
    <td>Where to forward emails to</td>
    <td><tt>sys.admin@emii.org.au</tt></td>
  </tr>
</table>

Usage
=====

