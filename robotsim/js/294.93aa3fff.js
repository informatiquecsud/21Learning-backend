"use strict";(self["webpackChunkquasar2_app"]=self["webpackChunkquasar2_app"]||[]).push([[294],{6294:(e,a,l)=>{l.r(a),l.d(a,{default:()=>I});l(2100),l(812),l(5363),l(71);var t=l(3673),n=l(1959),o=l(2323),s=l(9582),i=l(838),r=l(8825),d=l(1525);const c=["src","width","height"];function m(e,a,l,n,o,s){return(0,t.wg)(),(0,t.iD)("iframe",{class:"robotsim-container",src:e.src,frameborder:"0",width:e.width,height:e.height},"\n  ",8,c)}const u=(0,t.aZ)({name:"IFrameRobotSim",props:{src:{type:String,required:!0},width:{type:Number,required:!0},height:{type:Number,required:!0}}});var p=l(4260);const _=(0,p.Z)(u,[["render",m]]),f=_,h={class:"q-pb-lg",style:{maxWidth:"100%"}},y={props:{stdout:String},setup(e){const a=e,l=!0,s=((0,n.iH)(a.stdout),(0,n.iH)(null));return(0,t.bv)((()=>{})),(0,t.YP)((()=>a.stdout),((e,a)=>{s.value.setScrollPercentage("vertical",1)})),(a,n)=>{const i=(0,t.up)("q-scroll-area");return(0,t.wg)(),(0,t.j4)(i,{ref_key:"stdoutScrollArea",ref:s,dark:"",visible:l,style:{height:"250px"}},{default:(0,t.w5)((()=>[(0,t._)("pre",h,(0,o.zw)(e.stdout+"\n\n\n\n"),1)])),_:1},512)}}};var w=l(7704),v=l(7518),g=l.n(v);const b=y,k=b;g()(y,"components",{QScrollArea:w.Z});let x,N=e=>e;const q=(e,a)=>{const l=String.raw(x||(x=N`
from ast import *

class _FindDefs(NodeVisitor):
    def __init__(self):
        self.defs={}

    def visit_FunctionDef(self,node):
        #print("Found def!",type(node.name))
        self.generic_visit(node)
        self.defs[node.name]=node.name

    def get_defs(self):
        return self.defs


### Code to translate simple python code to be async. n.b. right now only sleep calls and imports are async in practice
# all calls to local functions are async as otherwise you can't run sleep in them
class _MakeAsyncCalls(NodeTransformer):
    def __init__(self,call_table):
        self.call_table=call_table
        self.in_main=False

    def visit_AsyncFunctionDef(self,node):
        # ignore anything that is already async except for the main
        if node.name=='__async_main':
            self.in_main=True
            self.generic_visit(node)
            self.in_main=False
        return node

    def visit_ImportFrom(self,node):
        if not self.in_main:
            return node
        elements=[]
        elements.append(Tuple([Constant(node.module),Constant(None)],ctx=Load()))
        # first call async code to import it into pyodide, then call the original import statement to make it be available here
        newNode=[Expr(value=Await(Call(Name('aimport',ctx=Load()),args=[List(elements,ctx=Load())],keywords=[]))),node]
        return newNode

    def visit_Import(self,node):
        if not self.in_main:
            return node
        elements=[]
        for c in node.names:
            thisElement=Tuple([Constant(c.name),Constant(c.asname)],ctx=Load())
            elements.append(thisElement)
        # first call async code to import it into pyodide, then call the original import statement to make it be available here
        newNode=[Expr(value=Await(Call(Name('aimport',ctx=Load()),args=[List(elements,ctx=Load())],keywords=[]))),node]
        return newNode

    def visit_FunctionDef(self,node):
        #print("Found functiondef")
        self.generic_visit(node) # make sure any calls are turned into awaits where relevant
        return AsyncFunctionDef(name=node.name,args=node.args,body=node.body,decorator_list=node.decorator_list,returns=node.returns)

    def _parse_call(self,name):
        allNames=name.split(".")
        retVal=Name(id=allNames[0],ctx=Load())
        allNames=allNames[1:]
        #print(dump(retVal))
        while len(allNames)>0:
            retVal=Attribute(value=retVal,attr=allNames[0],ctx=Load())
            allNames=allNames[1:]
        #print(dump(retVal))
        return retVal


    def visit_Call(self, node):
        target=node.func
        make_await=False
        nameParts=[]
        while type(target)==Attribute:
            nameParts=[target.attr]+nameParts
            target=target.value
        if type(target)==Name:
            nameParts=[target.id]+nameParts
        target_id=".".join(nameParts)
        simple_name=nameParts[-1]
        if target_id in self.call_table:
            make_await=True
        elif simple_name in self.call_table:
            make_await=True
        if make_await:
            nameNodes=self._parse_call(self.call_table[target_id])
            #print("make await",target_id,node.args,node.keywords)
            newNode=Await(Call(nameNodes,args=node.args,keywords=node.keywords))
            return newNode
        else:
            # external library call, ignore
            return Call(node.func,node.args,node.keywords)


class _LineOffsetter(NodeTransformer):
    def __init__(self,offset):
        self.offset=offset

    def visit(self, node):
        if hasattr(node,"lineno"):
            node.lineno+=self.offset
        if hasattr(node,"endlineno"):
            node.end_lineno+=self.offset
        self.generic_visit(node)
        return node


# todo make this for multiple code modules (and maybe to guess class types from the code..)
def __asyncify_sleep_delay(code_str,compile_mode='exec'):
    code_imports = "import asyncio\n"

    asleep_def = "async def __async_main():\n"

    extraLines=len(asleep_def.split("\n"))-1


    code_lines = []

    for line in code_str.splitlines():
        if 'import' in line.split('#')[0]:
            code_imports += line + '\n'
        else:
            code_lines += ["    "+line]

    all_code = code_imports
    all_code += asleep_def
    all_code += '\n'.join(code_lines)
    all_code += '\n'

    #all_code+="_loop.set_task_to_run_until_done(__async_main())\n"
    all_code+="asyncio.run(__async_main())\n"

    # print(all_code)

    oldTree=parse(all_code, mode='exec')

    defs=_FindDefs()
    defs.visit(oldTree)
    allDefs=defs.get_defs()
    # override sleep with asleep
    allDefs["sleep"]="asyncio.sleep"
    allDefs["delay"]="delay"
    allDefs["time.sleep"]="asyncio.sleep"
    newTree=fix_missing_locations(_MakeAsyncCalls(allDefs).visit(oldTree))
    newTree=_LineOffsetter(-extraLines).visit(newTree)

    with open('tree.dump', 'w') as f:
        f.write(dump(newTree))

    return newTree

    #return compile(newTree,filename="your_code.py",mode=compile_mode)

def __strip_async_main(new_ast):
    code = unparse(new_ast)
    lines = code.splitlines()
    final_lines = []

    in_async_main = False

    for line in lines:
        #print("currentline", line)
        if not in_async_main:
            if line.startswith('async def __async_main()'):
                in_async_main = True
            elif line.startswith('asyncio.run(__async_main())'):
                continue
            else:
                final_lines.append(line)
        elif in_async_main:
            if line.startswith('    '):
                final_lines.append(line[4:])
            elif line == '':
                final_lines.append(line)
            else:
                in_async_main = False

        #print('lines', final_lines)


    return '\n'.join(final_lines)

result = __asyncify_sleep_delay(code_to_compile,compile_mode='exec')
__strip_async_main(result)
`));return a.runPythonAsync(l,a.toPy({code_to_compile:e}))};l(5949);const C=(0,t.Uk)("Save & Run"),W=(0,t.Uk)("Reload"),U=(0,t.Uk)("Asyncify"),V=(0,t.Uk)("Share"),P=(0,t.Uk)("PyRobotSim"),S={style:{height:"100%"}},T=(0,t.Uk)(" REPL "),L={props:{},setup(e){const a=(0,r.Z)();function l(){a.dialog({title:"New file name",message:"What name should I give to the new file?",prompt:{model:"",type:"text"},cancel:!0,persistent:!0}).onOk((e=>{u.value.push({path:e,data:""})})).onCancel((()=>{})).onDismiss((()=>{}))}const c=(0,s.yj)(),m=(0,s.tv)(),u=(0,n.iH)([{path:"main.py",data:"",show:!0}]),p=(0,n.iH)("main.py"),_=(0,n.iH)(""),h={mode:"text/x-python",theme:"eclipse",lineNumbers:!0,smartIndent:!0,indentUnit:4,foldGutter:!0,styleActiveLine:!0},y=(0,n.iH)(50),w=(0,n.iH)(600),v=((0,n.iH)(""),(0,n.iH)("stdout")),g=(0,n.iH)(""),b=(0,n.iH)(0),x=(0,n.iH)(""),N=((0,n.iH)(0),(0,n.iH)(!1)),L=(0,n.iH)(null);let F=null;const D=!1,H="v0.20.0",A=async()=>{try{D?(window.languagePluginUrl=`${LOCAL_PYODIDE_SERVER_URL}`,await(0,i.ve)(`${LOCAL_PYODIDE_SERVER_URL}pyodide.js`)):(window.languagePluginUrl=`https://cdn.jsdelivr.net/pyodide/${H}/full/`,await(0,i.ve)(`https://cdn.jsdelivr.net/pyodide/${H}/full/pyodide.js`),F=await loadPyodide({indexURL:languagePluginUrl,stdin:window.prompt,stdout:E,stderr:e=>x.value+=e+"\n"}),window.pyodide=F,console.log("pyodide loading ...",F)),N.value=!0}catch(e){console.log(e),L.value=e}},E=e=>{console.log(e),g.value+=e+"\n",b.value+=1,console.log("stdout",g.value)},j=e=>{x.value+=e+"\n",console.log("stderr",x.value)},Z=(e,a)=>{e.forEach((e=>{a.FS.writeFile(e.path,e.data)}))},R=async()=>{g.value="",x.value="",localStorage.setItem("editorFiles",JSON.stringify(u.value)),Z(u.value,F),console.log("files",u.value);const e=z(p.value).data;let a;try{a=await q(e,F),_.value=a}catch(l){j(`Error while converting code to async code: \n${l}`),v.value="stderr"}try{await F.runPythonAsync(a)}catch(l){j(`Error while running code on virtual robot.\n${l}`),v.value="stderr"}},O=()=>{const e=localStorage.getItem("editorFiles");void 0!==e&&(u.value=JSON.parse(e))},Q=()=>{const e={...c.query,main:btoa(u.value[0].data)};m.replace({query:e})},$=(0,t.Fl)((()=>{const e={world:c.query.world};return Object.entries(e).map((([e,a])=>`${e}=${a}`)).join("&")})),I=async(e,a)=>{const l=new Headers;l.append("pragma","no-cache"),l.append("cache-control","no-cache"),a.forEach((a=>{const l=e+a.path;fetch(l,{method:"GET",mode:"cors",cache:"no-store"}).then((e=>e.text())).then((e=>{u.value.push({path:a.path,data:e,show:a.show})})).catch((e=>{alert(`Unable to download module from ${l}`)}))}))},Y=()=>{},z=e=>u.value.find((e=>e.path===p.value));return(0,t.bv)((async()=>{console.log("loading Pyodide"),await A(),g.value="",void 0!==c.query.main&&(u.value[0].data=atob(c.query.main));const e="/mbrobot/";await I(e,[{path:"mbrobot.py",show:!1},{path:"mbrobot2.py",show:!0},{path:"delay.py",show:!1},{path:"microbit.py",show:!1},{path:"mbrobotmot.py",show:!1},{path:"mbalarm.py",show:!1},{path:"music.py",show:!1},{path:"worlds.py",show:!1},{path:"simple_trail.py",show:!1}])})),(e,a)=>{const s=(0,t.up)("q-btn"),i=(0,t.up)("q-toolbar-title"),r=(0,t.up)("q-toolbar"),c=(0,t.up)("q-header"),m=(0,t.up)("q-tab"),b=(0,t.up)("q-tabs"),N=(0,t.up)("q-separator"),L=(0,t.up)("q-tab-panels"),F=(0,t.up)("q-tab-panel"),D=(0,t.up)("q-splitter");return(0,t.wg)(),(0,t.j4)(D,{modelValue:y.value,"onUpdate:modelValue":a[6]||(a[6]=e=>y.value=e)},{before:(0,t.w5)((()=>[(0,t.Wm)(c,{elevated:""},{default:(0,t.w5)((()=>[(0,t.Wm)(r,null,{default:(0,t.w5)((()=>[(0,t.Wm)(s,{color:"green",class:"q-ma-sm",onClick:R},{default:(0,t.w5)((()=>[C])),_:1}),(0,t.Wm)(s,{color:"white","text-color":"black",class:"q-ma-sm",onClick:O},{default:(0,t.w5)((()=>[W])),_:1}),(0,t.Wm)(s,{color:"white","text-color":"black",class:"q-ma-sm",onClick:(0,n.SU)(q)},{default:(0,t.w5)((()=>[U])),_:1},8,["onClick"]),(0,t.Wm)(s,{color:"white","text-color":"black",class:"q-ma-sm",onClick:Q},{default:(0,t.w5)((()=>[V])),_:1}),(0,t.Wm)(i,null,{default:(0,t.w5)((()=>[P])),_:1})])),_:1})])),_:1}),(0,t._)("div",S,[(0,t.Wm)(b,{modelValue:p.value,"onUpdate:modelValue":a[0]||(a[0]=e=>p.value=e),dense:"","no-caps":"",class:"text-grey","active-color":"primary","indicator-color":"primary",align:"justify"},{default:(0,t.w5)((()=>[((0,t.wg)(!0),(0,t.iD)(t.HY,null,(0,t.Ko)(u.value.filter((e=>e.show)),((e,a)=>((0,t.wg)(),(0,t.j4)(m,{name:e.path,key:a,label:e.path},null,8,["name","label"])))),128)),(0,t.Wm)(s,{class:"q-ma-sm",color:"white",icon:"add",label:"New ...","text-color":"black",onClick:l})])),_:1},8,["modelValue"]),(0,t.Wm)(N),(0,t.kq)("",!0),(0,t.Wm)(L,{modelValue:p.value,"onUpdate:modelValue":a[1]||(a[1]=e=>p.value=e),animated:""},{default:(0,t.w5)((()=>[((0,t.wg)(!0),(0,t.iD)(t.HY,null,(0,t.Ko)(u.value,((e,a)=>((0,t.wg)(),(0,t.j4)((0,n.SU)(d.ZP),{key:a,name:e.path,value:e.data,"onUpdate:value":a=>e.data=a,options:h,border:"",placeholder:"test placeholder",style:{height:"800px"},onChange:Y},null,8,["name","value","onUpdate:value"])))),128))])),_:1},8,["modelValue"])])])),after:(0,t.w5)((()=>[(0,t.Wm)(D,{horizontal:"",unit:"px",modelValue:w.value,"onUpdate:modelValue":a[5]||(a[5]=e=>w.value=e)},{before:(0,t.w5)((()=>[(0,t.Wm)(f,{src:`robotsim1/index.html?${(0,n.SU)($)}`,width:700,height:w.value},null,8,["src","height"])])),after:(0,t.w5)((()=>[(0,t._)("div",null,[(0,t.Wm)(b,{modelValue:v.value,"onUpdate:modelValue":a[2]||(a[2]=e=>v.value=e),dense:"",class:"text-grey","active-color":"primary","indicator-color":"primary",align:"justify"},{default:(0,t.w5)((()=>[(0,t.Wm)(m,{name:"stdout",label:"Stdout"}),(0,t.Wm)(m,{name:"stderr",label:"Stderr"}),(0,t.Wm)(m,{name:"repl",label:"REPL"}),(0,t.Wm)(m,{name:"asyncifiedCode",label:"Async"})])),_:1},8,["modelValue"]),(0,t.Wm)(N),(0,t.Wm)(L,{style:{"max-height":"200px"},modelValue:v.value,"onUpdate:modelValue":a[4]||(a[4]=e=>v.value=e),animated:""},{default:(0,t.w5)((()=>[(0,t.Wm)(F,{name:"stdout"},{default:(0,t.w5)((()=>[(0,t.Wm)(k,{stdout:g.value},null,8,["stdout"])])),_:1}),(0,t.Wm)(F,{name:"stderr"},{default:(0,t.w5)((()=>[(0,t._)("pre",null,(0,o.zw)(x.value),1)])),_:1}),(0,t.Wm)(F,{name:"repl"},{default:(0,t.w5)((()=>[T])),_:1}),(0,t.Wm)(F,{name:"asyncifiedCode"},{default:(0,t.w5)((()=>[(0,t.Wm)((0,n.SU)(d.ZP),{value:_.value,"onUpdate:value":a[3]||(a[3]=e=>_.value=e),options:{...h,readOnly:!0},border:"",height:"180px",onChange:e.change},null,8,["value","options","onChange"])])),_:1})])),_:1},8,["modelValue"])])])),_:1},8,["modelValue"])])),_:1},8,["modelValue"])}}};var F=l(218),D=l(3812),H=l(9570),A=l(8240),E=l(3747),j=l(2496),Z=l(3269),R=l(5869),O=l(5906),Q=l(6602);const $=L,I=$;g()(L,"components",{QSplitter:F.Z,QHeader:D.Z,QToolbar:H.Z,QBtn:A.Z,QToolbarTitle:E.Z,QTabs:j.Z,QTab:Z.Z,QSeparator:R.Z,QTabPanels:O.Z,QTabPanel:Q.Z})}}]);