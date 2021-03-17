RELEASE = `git rev-parse HEAD 2>/dev/null || cat REVISION 2>/dev/null`.chomp rescue nil
