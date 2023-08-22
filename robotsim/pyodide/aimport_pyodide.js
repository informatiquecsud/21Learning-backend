var aimport_src="\n\n# call into javascript to handle a single import\nimport asyncio\nimport js\nasync def _aimport(module,alias):\n    future = asyncio.get_event_loop().create_future()\n    js.pyodide_async_import(module,alias,future)\n    return (await future)\n\n# import list of module,alias pairs\nasync def aimport(namePairs):\n    for (module,alias) in namePairs:\n        await _aimport(module,alias)\n\n";function pyodide_async_import(o,i,t){console.log("Import ",o),i?pyodide.runPythonAsync("import "+o+" as "+i).then((o=>{t.set_result(1)}),(o=>{python_err_print(o)})):pyodide.runPythonAsync("import "+o).then((o=>{t.set_result(1)}),(o=>{python_err_print(o)}))}function aimport_pyodide_load(){pyodide.runPython("\n\timport js\n\timport importlib.util\n\tspec = importlib.util.spec_from_loader('aimport_pyodide', loader=None, origin=\"aimport_pyodide.py\")\n\taimport_pyodide = importlib.util.module_from_spec(spec)\n\tsys.modules['aimport_pyodide']=aimport_pyodide\n\texec(js.aimport_src, aimport_pyodide.__dict__)\n\t")}