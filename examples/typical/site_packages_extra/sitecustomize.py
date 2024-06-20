# This file is loaded by the Python interpreter and can alter the Python module loading process.
# We use it to inject lib/python into our PYTHON_PATH so that we can import modules relative to this directory.
import os
import sys

dirname = os.path.dirname(__file__)
# Add site_packages_extra/lib/python to path so we can import `hello`` without the site_packages_extra.lib.python prefix
sys.path.append(
    os.path.abspath(os.path.join(dirname, "../../../../site_packages_extra/lib/python"))
)
# Add repo root to the path
sys.path.append(os.path.abspath(os.path.join(dirname, "../../../..")))
