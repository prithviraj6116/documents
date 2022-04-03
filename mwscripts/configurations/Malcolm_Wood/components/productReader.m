classdef productReader < handle
   properties
       productKey;
       productName;
       productBaseCode;
       identifyingComponentName;
       root = matlabroot;
   end
   
   properties (Access = 'protected')
       productDependencies = 'not loaded';
       componentDependencies = 'not loaded';
   end
   
   methods
       
       %-------------------------
       function obj = productReader(key)
           obj.productKey = key;
       end

        %--------------------------------------------------------------------------
        function loadProduct(obj)
            dom = readProductFile(obj);
            depnodes = dom.getElementsByTagName('componentDep');
            comps = cell(depnodes.getLength,1);
            for i=1:depnodes.getLength
                node = depnodes.item(i-1);
                comps{i} = char(node.getAttribute('name'));
            end
            obj.componentDependencies = comps(:);
            depnodes = dom.getElementsByTagName('productDep');
            p = cell(depnodes.getLength,1);
            for i=1:depnodes.getLength
                node = depnodes.item(i-1);
                p{i} = char(node.getAttribute('name'));
            end
            obj.productDependencies = p(:);
            
            xpathFactory = javax.xml.xpath.XPathFactory.newInstance();
            xpathObj = xpathFactory.newXPath();

            obj.productName = mt_getxmlstring(dom,'//productName/text()');
            
            % Not all products have basecodes.
            obj.productBaseCode = mt_getxmlstring(dom,'//baseCode/text()');
            
            query = '//identifyingComponentName/text()';
            nodeSet = xpathObj.evaluate(query, dom, javax.xml.xpath.XPathConstants.NODESET);
            if nodeSet.getLength
                obj.identifyingComponentName = char(nodeSet.item(0).getTextContent);
            else
                obj.identifyingComponentName = obj.productKey;
            end
            
        end
        
        %--------------------------------------
        function filename = getProductFile(obj)
            filename = fullfile(obj.root,'config','products',[obj.productKey '.xml']);
        end
        
        %--------------------------------------
        function dom = readProductFile(obj)
            filename = getProductFile(obj);
            dom = xmlread(org.xml.sax.InputSource(filename));
        end
        
        function p = getProductDependencies(obj)
            if ~iscell(obj.productDependencies)
                obj.productDependencies = mt_getxmlstrings(obj.getProductFile,...
                    '//requiredProducts/productDep/@name');
            end
            p = obj.productDependencies;
        end
        
        function c = getComponentDependencies(obj)
            if ~iscell(obj.componentDependencies)
                try
                    obj.componentDependencies = mt_getxmlstrings(obj.getProductFile,...
                        '//dependsOn/componentDep/@name');
                catch E
                    obj.componentDependencies = {E.message};
                end
            end
            c = obj.componentDependencies;
        end
            
   end
end