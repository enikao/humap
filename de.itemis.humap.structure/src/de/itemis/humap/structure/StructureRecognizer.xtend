package de.itemis.humap.structure

import de.itemis.humap.structure.information.AbstractRecognizerInformation
import de.itemis.humap.structure.information.BoundKind
import de.itemis.humap.structure.information.Box
import de.itemis.humap.structure.information.DataKind
import de.itemis.humap.structure.information.Label
import de.itemis.humap.structure.information.LabelKind
import de.itemis.humap.structure.information.Line
import java.util.Collection
import java.util.Collections
import java.util.LinkedHashMap
import java.util.List
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.ENamedElement
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference

import static java.lang.Math.*

class StructureRecognizer {
	private EPackage rootPackage
	
	def recognizePackage(EPackage it) {
		rootPackage = it
		
		EClassifiers.filter(typeof(EClass)).forEach [ clazz |
			clazz.recognizeCached.forEach [ info |
				print(info.concatInfo)
			]
		]
	}
	
	private LinkedHashMap<ENamedElement, List<? extends AbstractRecognizerInformation>> recognizeCache = newLinkedHashMap 
	
	def List<? extends AbstractRecognizerInformation> recognizeCached(ENamedElement it) {
		if (!recognizeCache.containsKey(it)) {
			//infinite recursion protection
			recognizeCache.put(it, null)
			recognizeCache.put(it, recognize(it))
		}
		
		return recognizeCache.get(it)
	}
	
	def dispatch List<? extends AbstractRecognizerInformation> recognize(EClass it) {
		val subFeatures = EAllStructuralFeatures.map[ feature |
			feature.recognizeCached
		].flatten.toList
		
		var int attributeCount = 0
		var int referenceCount = 0

		for (feature : EAllStructuralFeatures) {
			if (feature instanceof EAttribute) {
				attributeCount = attributeCount + 1
			} else if (feature instanceof EReference) {
				referenceCount = referenceCount + 1
			}
		}
		
		if (referenceCount == 0) {
			// only attributes
			if (attributeCount == 1) {
				//only one attribute
				return createOnlyOneAttribute(subFeatures)
			} else if (onlySingleBounds(subFeatures)) {
				// only single bound attributes
				return createConcatenatedAttribute(subFeatures)
			} else {
				// box with compartments
				return createBoxWithCompartments(subFeatures)
			}
		} else if (
			referenceCount == 1 &&
			attributeCount == 0 &&
			(EAllStructuralFeatures.head as EReference).containment
		) {
			// replace
			return createProxy(subFeatures.head)
		} else if (
			referenceCount == 1 &&
			EAllStructuralFeatures.filter(typeof(EReference)).head.upperBound <= 1 &&
			!EAllStructuralFeatures.filter(typeof(EReference)).head.containment &&
			isContainedSomewhere
		) {
			// edge reference target -- eContainer
			return createLineToContainer(EAllStructuralFeatures.filter(typeof(EReference)).head.recognizeCached.head)
		}
		
		return null
	}
	
	def dispatch List<AbstractRecognizerInformation>  recognize(EAttribute it) {
		
	}
	
	def dispatch List<AbstractRecognizerInformation>  recognize(EReference it) {
		
	}
	
	def createOnlyOneAttribute(Collection<? extends AbstractRecognizerInformation> features) {
		return createProxy(features.head as Label)
	}
	
	def createConcatenatedAttribute(Collection<? extends AbstractRecognizerInformation> features) {
		val result = new Label()
		
		result.boundKind = BoundKind::SINGLE
		
		for (currentFeature : features) {
			val otherLabel = currentFeature as Label
			
			result.lowerBound = min(result.lowerBound, otherLabel.lowerBound)
			result.upperBound = max(result.upperBound, otherLabel.upperBound)
			
			if (null == result.dataKind) {
				result.dataKind = otherLabel.dataKind
			} else if (result.dataKind != otherLabel.dataKind) {
				result.dataKind = DataKind::MIXED
			}
			
			if (null == result.labelKind) {
				result.labelKind = otherLabel.labelKind
			} else if (result.labelKind != otherLabel.labelKind) {
				result.labelKind = LabelKind::TEXT
			}
			
			result.replacedInformations.add(otherLabel)
		}
		
		return Collections::singletonList(result)
	}
	
	def createBoxWithCompartments(EClass clazz, Collection<? extends AbstractRecognizerInformation> features) {
		val result = new Box()
		
		result.eClass = clazz
		result.attributeCount = features.size
		result.referenceCount = 0
		
		var int compartmentCounter = 0
		
		for (currentFeature : features) {
			result.containedInformations.add(currentFeature)
			result.compartmentMapping.put(currentFeature, compartmentCounter)
			compartmentCounter = compartmentCounter + 1
		}
		
		return Collections::singletonList(result)
	}
	
	def createProxy(AbstractRecognizerInformation feature) {
		if (feature instanceof Box) {
			val otherBox = feature as Box
			val result = new Box()
			
			result.attributeCount = otherBox.attributeCount
			result.referenceCount = otherBox.referenceCount
			
			result.containedInformations.addAll(otherBox.containedInformations)
			result.compartmentMapping.putAll(otherBox.compartmentMapping)
			
			result.replacedInformations.add(otherBox)
			
			return Collections::singletonList(result)
		} else if (feature instanceof Line) {
			val otherLine = feature as Line
			val result = new Line()
			
			result.boundKind = otherLine.boundKind
			result.lowerBound = otherLine.lowerBound
			result.upperBound = otherLine.upperBound
			
			result.containedInformations.addAll(otherLine.containedInformations)
			
			result.replacedInformations.add(otherLine)
				
			return Collections::singletonList(result)
		} else if (feature instanceof Label) {
			val otherLabel = feature as Label
			val result = new Label()
			
			result.boundKind = otherLabel.boundKind
			result.lowerBound = otherLabel.lowerBound
			result.upperBound = otherLabel.upperBound
			
			result.dataKind = otherLabel.dataKind
			result.labelKind = otherLabel.labelKind
	
			result.replacedInformations.add(otherLabel)
			
			return Collections::singletonList(result)
		}
	}
	
	def createLineToContainer(EClass clazz, AbstractRecognizerInformation feature) {
		val result = <AbstractRecognizerInformation>newArrayList
		
		val containers = clazz.collectContainers
		
		containers.forEach [ container |
			val line = new Line()
			
			line.boundKind = BoundKind::SINGLE
			line.lowerBound = 0
			line.upperBound = 1
			
			line.containedInformations.add(feature)
			// TODO: Can we really only use first?
			line.containedInformations.add(container.recognizeCached.head)
			
			result.add(line)
		]
		
		return result
	}
	
	def boolean onlySingleBounds(Collection<? extends AbstractRecognizerInformation> features) {
		features.forall[BoundKind::SINGLE == boundKind]
	}
	
	def dispatch concatInfo(Box it) {
		'''box «FQName» {
			«IF !compartmentMapping.empty»
				«FOR contained : compartmentMapping.keySet»
					«compartmentMapping.get(contained)»: «contained.concatInfo»
				«ENDFOR»
			«ELSE»
				«FOR contained : containedInformations»
					«contained.concatInfo»
				«ENDFOR»
			«ENDIF»
		}'''
	}

	def dispatch concatInfo(Line it) {
		'''line «FQName» {
			«FOR contained : containedInformations»
				«contained.concatInfo»
			«ENDFOR»
		}'''
	}

	def dispatch concatInfo(Label it) {
		'''label «FQName» {
			«FOR contained : containedInformations»
				«contained.concatInfo»
			«ENDFOR»
		}'''
	}
	
	def boolean isContainedSomewhere(EClass eClass) {
		rootPackage.EClassifiers.filter(typeof(EClass)).exists[ clazz |
			clazz.EAllReferences.exists[ reference |
				reference.container && eClass == reference.EType
			]
		]
	}
	
	def collectContainers(EClass eClass) {
		val result = <EClass>newLinkedHashSet
		
		result += rootPackage.EClassifiers.filter(typeof(EClass)).filter[ clazz |
			clazz.EAllReferences.exists[ reference |
				reference.container && eClass == reference.EType
			]
		]
		
		return result
	}
}