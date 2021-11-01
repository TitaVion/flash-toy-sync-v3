package controllers {
	
	import components.HierarchyChildInfo;
	import core.TPDisplayObject;
	import core.TPMovieClip;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import states.AnimationInfoStates;
	import states.HierarchyStates;
	import ui.HierarchyPanel;
	import utils.ArrayUtil;
	import utils.HierarchyUtil;
	
	/**
	 * ...
	 * @author notSafeForDev
	 */
	public class HierarchyPanelController {
		
		private var hierarchyStates : HierarchyStates;
		
		private var hierarchyPanel : HierarchyPanel;
		
		private var expandedChildren : Vector.<DisplayObject>;
		
		public function HierarchyPanelController(_hierarchyStates : HierarchyStates, _hierarchyPanel : HierarchyPanel) {
			hierarchyStates = _hierarchyStates;
			
			hierarchyPanel = _hierarchyPanel;
			hierarchyPanel.toggleExpandEvent.listen(this, onToggleExpand);
			
			expandedChildren = new Vector.<DisplayObject>();
		}
		
		public function update() : void {
			if (AnimationInfoStates.isLoaded.value == false) {
				return;
			}
			
			hierarchyStates._hierarchyPanelInfoList.setValue(getInfoForActiveChildren());
		}
		
		private function createInitialChildInfo(_tpDisplayObject : TPDisplayObject, _depth : Number, _childIndex : Number) : HierarchyChildInfo {
			var info : HierarchyChildInfo = new HierarchyChildInfo();
			info.child = _tpDisplayObject;
			info.depth = _depth;
			info.childIndex = _childIndex;
			info.isExpandable = false;
			info.isExpanded = ArrayUtil.includes(expandedChildren, _tpDisplayObject.sourceDisplayObject);
			
			return info;
		}
		
		private function onToggleExpand(_child : TPDisplayObject) : void {
			var index : Number = ArrayUtil.indexOf(expandedChildren, _child.sourceDisplayObject);
			
			var didExpand : Boolean = index < 0;
			if (didExpand == true) {
				expandedChildren.push(_child.sourceDisplayObject);
				return;
			}
			
			expandedChildren.splice(index, 1);
			
			for (var i : Number = 0; i < expandedChildren.length; i++) {
				var parents : Vector.<DisplayObjectContainer> = TPDisplayObject.getParents(expandedChildren[i]);
				index = ArrayUtil.indexOf(parents, _child.sourceDisplayObject);
				if (index >= 0) {
					expandedChildren.splice(i, 1);
					i--;
				}
			}
		}
		
		private function getInfoForActiveChildren() : Array {
			var root : TPMovieClip = AnimationInfoStates.animationRoot.value;
			var rootInfo : HierarchyChildInfo = createInitialChildInfo(root, 0, 0);
			
			var infoList : Array = [];
			var expandableChildren : Vector.<DisplayObject> = new Vector.<DisplayObject>();
			
			infoList.push(rootInfo);
			
			TPMovieClip.iterateOverChildren(root.sourceMovieClip, this, getInfoForActiveChildrenIterator, [infoList, expandableChildren]);
			
			for (var i : Number = 0; i < infoList.length; i++) {
				var info : HierarchyChildInfo = infoList[i];
				var child : TPDisplayObject = info.child;
				
				var isParentExpanded : Boolean = ArrayUtil.includes(expandedChildren, child.parent);
				
				if (isParentExpanded == false && i > 0) {
					infoList.splice(i, 1);
					i--;
					continue;
				}
				
				var isChildExpandable : Boolean = (i == 0 && infoList.length > 1) || ArrayUtil.includes(expandableChildren, child.sourceDisplayObject);
				info.isExpandable = isChildExpandable;
			}
			
			return infoList;
		}
		
		private function getInfoForActiveChildrenIterator(_child : MovieClip, _depth : Number, _childIndex : Number, _infoList : Array, _expandableChildren : Vector.<DisplayObject>) : Number {
			var tpMovieClip : TPMovieClip = new TPMovieClip(_child);
			
			var parent : DisplayObjectContainer = tpMovieClip.parent;
			var isParentMarkedAsExpandable : Boolean = ArrayUtil.includes(_expandableChildren, parent);
			var isParentExpanded : Boolean = ArrayUtil.includes(expandedChildren, parent);
			
			if (isParentMarkedAsExpandable == true && isParentExpanded == false) {
				return TPMovieClip.ITERATE_SKIP_SIBLINGS;
			}
			
			var hasNestedAnimations : Boolean = TPMovieClip.hasNestedAnimations(_child);
			if (hasNestedAnimations == false && tpMovieClip.totalFrames == 1) {
				return TPMovieClip.ITERATE_SKIP_NESTED;
			}
			
			if (isParentExpanded == true || isParentMarkedAsExpandable == false) {
				if (isParentMarkedAsExpandable == false) {
					_expandableChildren.push(parent);
				}
				
				_infoList.push(createInitialChildInfo(tpMovieClip, _depth, _childIndex));
			}
			
			return TPMovieClip.ITERATE_CONTINUE;
		}
	}
}