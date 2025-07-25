This is a bash script which automatically approves Teleport JIT requests. If /home/teleport-bot/lockfile is present, it locks all sessions using the role "contractor-admin." 
If the file is not present, it automatically approves requests for that role.

The accompanying service files are for running this script automatically using rotating credentials from Machine ID.

The role is the one used to approve this with Machine ID.
