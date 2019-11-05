# Quick start

```bash
curl bootstrap.f0cal.com/master | python3 - --help
```
or 
```
git clone https://github.com/f0cal/bootstrap && \
  ./bootstrap/bin/bootstrap.py --help
```

# About

`bin/bootstrap.py` is a small CLI installer for various other pieces of `f0cal`
code. It's purpose is to quickly build a virtual environement and install the
code required for both end users and developers. Under the hood, it uses
`saltstack` to perform orchestrations on the local OS.

[docs](f0cal.com/docs#bootstrap)
