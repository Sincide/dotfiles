#!/usr/bin/env python3

from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

# Use system packages on Arch Linux - no pip requirements
requirements = [
    # All dependencies should be installed via pacman/yay
    # See requirements.txt for the actual package names
]

setup(
    name="gptdiag",
    version="1.0.0",
    author="System Administrator",
    author_email="admin@localhost",
    description="Advanced TUI-based system diagnostic and monitoring tool with AI integration",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/user/gptdiag",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: System Administrators",
        "License :: OSI Approved :: MIT License",
        "Operating System :: POSIX :: Linux",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Topic :: System :: Monitoring",
        "Topic :: System :: Systems Administration",
    ],
    python_requires=">=3.8",
    install_requires=requirements,
    entry_points={
        "console_scripts": [
            "gptdiag=gptdiag.main:main",
        ],
    },
    include_package_data=True,
    package_data={
        "gptdiag": ["config/*.yaml", "templates/*.txt"],
    },
) 