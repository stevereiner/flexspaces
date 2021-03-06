package org.integratedsemantics.flexspaces.control.delegate.webscript.wcm
{
    import com.universalmind.cairngorm.business.Delegate;
    
    import mx.collections.ArrayCollection;
    import mx.rpc.IResponder;
    
    import org.integratedsemantics.flexspaces.control.delegate.webscript.WebScriptService;
    import org.integratedsemantics.flexspaces.control.delegate.webscript.event.SuccessEvent;
    import org.integratedsemantics.flexspaces.control.error.ErrorMgr;
    import org.integratedsemantics.flexspaces.model.wcm.folder.WcmFolder;
    import org.integratedsemantics.flexspaces.model.wcm.tree.WcmTreeNode;


    /**
     * Gets avm tree data: stores for first level, folders at next levels, via web scripts
     * 
     */
    public class WcmTreeDelegate extends Delegate
    {
        private var path:String;
        
        /**
         * Constructor
         * 
         * @param commandHandlers responder with result and fault handlers to respond to
         * @param serviceName  service name
         * 
         */
        public function WcmTreeDelegate(commandHandlers:IResponder=null, serviceName:String="")
        {
            super(commandHandlers, serviceName);
        }

        /**
         * Gets folder tree data for path (one level of children)
         *  
         * @storeId   store id of avm store (i.e. "test--admin", etc.)
         * @path      path including /www/avm_webapps 
         */
        public function getFolders(storeId:String, path:String):void
        {
            this.path = path;
            
            try
            {        
                var url:String = "/flexspaces/wcm/tree";
                
                var webScript:WebScriptService = new WebScriptService(url, WebScriptService.GET, onTreeDataSuccess);
                
                var params:Object = new Object();
                
                params.storeid = storeId;
                params.path = path;
                
                webScript.execute(params);
            }
            catch (error:Error)
            {
                ErrorMgr.getInstance().raiseError(ErrorMgr.APPLICATION_ERROR, error);
            }
        }
        
        /**
         * onTreeDataSuccess event handler
         * 
         * @param event success event
         */
        protected function onTreeDataSuccess(event:SuccessEvent):void
        {
            var result:XML = event.result as XML;

            var currentNode:WcmTreeNode =  new WcmTreeNode(result.folder.storeId, result.folder.name, result.folder.id);
            
            currentNode.name = result.folder.name;                    

            currentNode.nodeRef = result.folder.noderef;                    

            currentNode.storeProtocol = result.folder.storeProtocol;                    
            currentNode.storeId = result.folder.storeId;                    
            currentNode.id = result.folder.id;                    

            currentNode.path = "/AVM/" + currentNode.storeId + path;
            currentNode.displayPath = "/AVM/" + currentNode.storeId + path;
                            
            currentNode.readPermission = (result.folder.readPermission == "true");
            currentNode.writePermission = (result.folder.writePermission == "true");
            currentNode.deletePermission = (result.folder.deletePermission == "true");
            currentNode.createChildrenPermission = (result.folder.createChildrenPermission == "true");
   
            currentNode.children = new ArrayCollection();

            for each (var folder:XML in result.folder.children.folder)
            {
                var childNode:WcmTreeNode = new WcmTreeNode(folder.storeId, folder.name, folder.id);
                
                childNode.name = folder.name;                    

                childNode.nodeRef = folder.noderef;                    

                childNode.storeProtocol = folder.storeProtocol;                    
                childNode.storeId = folder.storeId;                    
                childNode.id = folder.id;                    

                if (path == "/")
                {
                    childNode.path = currentNode.path + childNode.name; 
                    childNode.displayPath = currentNode.displayPath + childNode.name;    
                }
                else
                {
                    childNode.path = currentNode.path + "/" + childNode.name; 
                    childNode.displayPath = currentNode.displayPath + "/" + childNode.name;                            
                }
                childNode.parentPath = currentNode.path;    
                                    
                childNode.readPermission = (folder.readPermission == "true");
                childNode.writePermission = (folder.writePermission == "true");
                childNode.deletePermission = (folder.deletePermission == "true");
                childNode.createChildrenPermission = (folder.createChildrenPermission == "true");

                currentNode.children.addItem(childNode);
            }
            currentNode.hasBeenLoaded = true;
        	        	
            notifyCaller(currentNode, event);
        }


        /**
         * Gets list of avm stores
         *  
         */
        public function getStores():void
        {
            try
            {                   
                var url:String = "/flexspaces/wcm/avmStores";
                
                var webScript:WebScriptService = new WebScriptService(url, WebScriptService.GET, onStoresSuccess);
                
                var params:Object = new Object();
                
                webScript.execute(params);
            }
            catch (error:Error)
            {
                ErrorMgr.getInstance().raiseError(ErrorMgr.APPLICATION_ERROR, error);
            }
        }
        
        /**
         * onStoresSuccess event handler
         * 
         * @param event success event
         */
        protected function onStoresSuccess(event:SuccessEvent):void
        {
            var result:XML = event.result as XML;
            
            var currentNode:WcmTreeNode = new WcmTreeNode("AVM", "AVM", "AVM");
            currentNode.path = "/AVM";
       
            currentNode.children = new ArrayCollection();

            for each (var store:XML in result.store)
            {
                if ( WcmFolder.displayStore(store.id) == true)
                {
                    var childNode:WcmTreeNode = new WcmTreeNode(store.id, store.name, store.id);
                    childNode.path = "/AVM/" + store.id;
                    childNode.displayPath= "/AVM/" + store.id;
                    childNode.createdDate = store.createdDate;
                    childNode.name = store.name;
                    childNode.id = store.id;
                    currentNode.children.addItem(childNode);
                }
            }
            currentNode.hasBeenLoaded = true;
            
            notifyCaller(currentNode, event);
        }
        
    }
}