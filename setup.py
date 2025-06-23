from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="openwebui-installer",
    version="0.1.0",
    author="Open WebUI Team",
    author_email="team@openwebui.com",
    description="A macOS installer for Open WebUI with native Ollama integration",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/open-webui/openwebui-installer",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Environment :: MacOS X",
        "Intended Audience :: Developers",
        "Intended Audience :: End Users/Desktop",
        "License :: OSI Approved :: MIT License",
        "Operating System :: MacOS :: MacOS X",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Topic :: Software Development :: Libraries :: Python Modules",
        "Topic :: System :: Installation/Setup",
        "Topic :: System :: Systems Administration",
    ],
    python_requires=">=3.9",
    install_requires=[
        "click==8.2.1",
        "docker==7.1.0",
        "PyQt6==6.9.1",
        "requests==2.32.4",
        "rich==14.0.0",
        "psutil==5.9.8",
    ],
    entry_points={
        "console_scripts": [
            "openwebui-installer=openwebui_installer.cli:cli",
            "openwebui-installer-gui=openwebui_installer.gui:main",
        ],
    },
    package_data={
        "openwebui_installer": ["resources/*"],
    },
)
