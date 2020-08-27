from setuptools import setup

setup(
    name="dbmanage",
    version="0.1",
    py_modules=["manage"],
    install_requires=["Click", "gql>=3.0.0a1"],
    entry_points="""
        [console_scripts]
        dbmanage=manage:cli
    """,
)
